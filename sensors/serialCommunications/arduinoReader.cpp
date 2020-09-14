#include <iostream>
#include <thread>
#include <chrono>
#include <mex.h>
#include <tchar.h>

#include "private/Serial.h"


//-----------------------------------------------------------------------------
#define   USAGE_ERROR()                                                     \
  mexErrMsgIdAndTxt ( "arduinoReader:usage"                                 \
                    , "Usage:\n"                                            \
                      "    arduinoReader('init', portName)\n"               \
                      "    arduinoReader('end')\n"                          \
                      "    arduinoReader('end', true)         % forced\n"   \
                      "    arduinoReader('poll')\n"                         \
                      "    arduinoReader('poll', pollIndex)   % debug\n"    \
                      "    [...] = arduinoReader('get')\n"                  \
                      "For debugging:\n"                                    \
                      "    arduinoReader('send','...')\n"                   \
                      "    str = arduinoReader('raw')\n"                    \
                    );

#define   PACKET_ERROR(str, strLength, numTokens)                           \
  {                                                                         \
    str[strLength-1]  = 0;                                                  \
    mexErrMsgIdAndTxt ( "arduinoReader:parsing"                             \
                      , "The received message '%s' does not match the expected number of tokens %d."  \
                      , str, numTokens                                      \
                      );                                                    \
  }

// I/O error descriptions
static const char*  CSerialError[]
    = { "Unknown"
      , "Break condition detected"
      , "Framing error"
      , "I/O device error"
      , "Unsupported mode"
      , "Character buffer overrun, next byte is lost"
      , "Input buffer overflow, byte lost"
      , "Input parity error"
      , "Output buffer full"
      };


// Send this character to request mouse displacement
static const char       REQUEST_CHAR[]    = "m";
static const char       REQUEST_FORMAT[]  = "m%d\n";
static const char       SEPARATOR_CHAR    = ';';
static const char       TERMINATOR_CHAR   = '\n';

// Lengths of buffers   
static const int        PORT_LENGTH       = 50;
static const int        CMD_LENGTH        = 5;
static const int        COMM_LENGTH       = 100;

// Wait time
std::chrono::milliseconds   PASS_MS       = std::chrono::milliseconds(1);
static const int        READ_TIMEOUT      = 100;       // in ms

//-----------------------------------------------------------------------------
static CSerial          serial;

static void cleanup()
{
  //serial.Purge();
  if (serial.IsOpen())
    serial.Close();
}

//-----------------------------------------------------------------------------
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  //----- Parse arguments
  if (nrhs < 1 || !mxIsChar(prhs[0]))
    USAGE_ERROR();
  
  char                  command[CMD_LENGTH];
  mxGetString(prhs[0], command, CMD_LENGTH);


  //----- Initialize serial communications
  if (strcmp(command, "init") == 0) {
    if (nlhs > 0 || nrhs != 2)      USAGE_ERROR();
    if (serial.IsOpen())
      mexErrMsgIdAndTxt("arduinoReader:init", "A serial port is already open. Issue the command 'end' before 'init'.");

    // Setup communication parameters
    char                portName[PORT_LENGTH];
    mxGetString(prhs[1], portName, PORT_LENGTH);
    serial.Open(portName);
    serial.Setup(CSerial::EBaudrate(250000), CSerial::EData8, CSerial::EParNone,CSerial::EStop1);
    //serial.SetupHandshaking(CSerial::EHandshakeOff);
    serial.SetupHandshaking(CSerial::EHandshakeHardware);    // required for native port
    serial.SetupReadTimeouts(CSerial::EReadTimeoutNonblocking);
    //serial.SetEventChar(TERMINATOR_CHAR);
    
    if (!serial.IsOpen())
      mexErrMsgIdAndTxt("arduinoReader:init", "Failed to initialize serial communications with %s.", portName);

    mexAtExit(cleanup);
  }

  
  //----- Terminate serial communications
  else if (strcmp(command, "end") == 0) {
    if (nlhs > 0 || nrhs > 2)   USAGE_ERROR();

    if (serial.IsOpen())
      cleanup();
    else if (nrhs < 2 || mxGetScalar(prhs[1]) == 0)
      mexErrMsgIdAndTxt("arduinoReader:end", "There is currently no open serial port.");
  }

  
  //----- Send polling message
  else if (strcmp(command, "poll") == 0) {
    if (nrhs > 2)           USAGE_ERROR();
    if (!serial.IsOpen())
      mexErrMsgIdAndTxt("arduinoReader:poll", "Serial communications have not been properly initiated.");

    // Clear input buffer so that we don't run into problems with too high of a communications
    // rate and blocking up the Arduino by having a ton of unsent data in its output buffer
    DWORD                   bytesRead     = 0;
    char                    junk[COMM_LENGTH+2];
    do {
      if (serial.Read(junk, COMM_LENGTH, &bytesRead))
        mexErrMsgIdAndTxt("arduinoReader:poll", "Serial read error:  %s.", CSerialError[serial.GetError()]);
    } while (bytesRead > 0);

    DWORD                   bytesWritten  = 0;

    // Format for sending data on top of the poll request character
    if (nrhs > 1) {
      char                  buffer[COMM_LENGTH+2];
      sprintf(buffer, REQUEST_FORMAT, static_cast<int>( mxGetScalar(prhs[1]) ));
      if (serial.Write(buffer, &bytesWritten))
        mexErrMsgIdAndTxt("arduinoReader:poll", "Serial write error:  %s.", CSerialError[serial.GetError()]);
    }

    // Format for poll request character only
    else if (serial.Write(REQUEST_CHAR, &bytesWritten))
      mexErrMsgIdAndTxt("arduinoReader:poll", "Serial write error:  %s.", CSerialError[serial.GetError()]);

    // Sanity check that we have written some number of bytes
    if (bytesWritten < 1)
      mexErrMsgIdAndTxt("arduinoReader:poll", "Failed to write request command to serial port.");
  }


  //----- Receive message, blocking call
  else if (strcmp(command, "get") == 0) {
    if (nlhs < 1 || nrhs != 1) USAGE_ERROR();
    if (!serial.IsOpen())
      mexErrMsgIdAndTxt("arduinoReader:get", "Serial communications have not been properly initiated.");

    DWORD                   bytesRead     = 0;
    char                    buffer[COMM_LENGTH+2];
    for (int iter = 0; iter < READ_TIMEOUT; ++iter) {
      // Wait for a line to be received
      if (serial.WaitEvent(0, 1)) {
        std::this_thread::sleep_for(PASS_MS);
        continue;
      }

      const CSerial::EEvent eventType     = serial.GetEventType();
      if (eventType & CSerial::EEventError)
        mexErrMsgIdAndTxt("arduinoReader:get", "Serial event error:  %s.", CSerialError[serial.GetError()]);
      if (!(eventType & CSerial::EEventRecv)) {
        std::this_thread::sleep_for(PASS_MS);
        continue;
      }

      // Read buffer and parse according to expected number of tokens
      if (serial.Read(buffer, COMM_LENGTH, &bytesRead))
        mexErrMsgIdAndTxt("arduinoReader:get", "Serial read error:  %s.", CSerialError[serial.GetError()]);
      if (bytesRead < 2*nlhs) {
        buffer[bytesRead]   = 0;
        mexErrMsgIdAndTxt("arduinoReader:get", "Invalid reply '%s' received (too short to contain %d items).", buffer, nlhs);
      }

      DWORD                 position      = 0;
      int                   token         = -999;
      for (int iTok = 0; iTok < nlhs; ++iTok) {
        int                 numParsed;
        if (sscanf(buffer + position, "%d%n", &token, &numParsed) <= 0)
          PACKET_ERROR(buffer, bytesRead, nlhs);

        position           += numParsed;
        if (position >= bytesRead || (buffer[position] != SEPARATOR_CHAR) && (buffer[position] != TERMINATOR_CHAR))
          PACKET_ERROR(buffer, bytesRead, nlhs);

        plhs[iTok]          = mxCreateDoubleScalar(token);
        ++position;
      }

      //if (bytesRead > 0)
      //  mexPrintf("%s\n", buffer);
      //else
      //  mexPrintf("???\n");
      return;
    }
    
    mexErrMsgIdAndTxt("arduinoReader:get", "Timed out while waiting for a reply.");
  }



  //----- Send custom message
  else if (strcmp(command, "send") == 0) {
    if (nrhs != 2)          USAGE_ERROR();
    if (!serial.IsOpen())
      mexErrMsgIdAndTxt("arduinoReader:send", "Serial communications have not been properly initiated.");

    char                    buffer[COMM_LENGTH+2];
    mxGetString(prhs[1], buffer, COMM_LENGTH);

    DWORD                   bytesWritten  = 0;
    if (serial.Write(buffer, &bytesWritten))
      mexErrMsgIdAndTxt("arduinoReader:send", "Serial write error:  %s.", CSerialError[serial.GetError()]);

    if (bytesWritten < 1)
      mexErrMsgIdAndTxt("arduinoReader:send", "Failed to write '%s' to serial port.", buffer);
  }


  //----- Receive message, blocking call
  else if (strcmp(command, "raw") == 0) {
    if (nlhs < 1 || nrhs != 1) USAGE_ERROR();
    if (!serial.IsOpen())
      mexErrMsgIdAndTxt("arduinoReader:raw", "Serial communications have not been properly initiated.");

    DWORD                   bytesRead     = 0;
    char                    buffer[COMM_LENGTH+2];
    for (int iter = 0; iter < READ_TIMEOUT; ++iter) {
      // Wait for a line to be received
      if (serial.WaitEvent(0, 1)) {
        std::this_thread::sleep_for(PASS_MS);
        continue;
      }

      const CSerial::EEvent eventType     = serial.GetEventType();
      if (eventType & CSerial::EEventError)
        mexErrMsgIdAndTxt("arduinoReader:raw", "Serial event error:  %s.", CSerialError[serial.GetError()]);
      if (!(eventType & CSerial::EEventRecv)) {
        std::this_thread::sleep_for(PASS_MS);
        continue;
      }

      // Read buffer and parse according to expected number of tokens
      if (serial.Read(buffer, COMM_LENGTH, &bytesRead))
        mexErrMsgIdAndTxt("arduinoReader:raw", "Serial read error:  %s.", CSerialError[serial.GetError()]);
      plhs[0]               = mxCreateStringFromNChars(buffer, bytesRead);

      return;
    }
    
    mexErrMsgIdAndTxt("arduinoReader:raw", "Timed out while waiting for a reply.");
  }
}
