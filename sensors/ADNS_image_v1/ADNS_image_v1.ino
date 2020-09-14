#include <SPI.h>
// This program responds to 'i' and 'q' serial commands from the host computer. For 'i', it 
// will read an image from the ADNS380 and send it as an unsigned byte array to the 
// host computer. For  'q' it sends the "SQUAL' value. 
// This program requires the RST pin on the ADNS3080 board to be connected to pin 8
// on the Due. RST is used to re-initiate motion computation after an image frame read.
// Use of the HIREZ option sets the ADNS3080 cpi to 1600 from the default of 400. The
// is rewritten to the chip after each reset. It is not clear if this affects image acquistion.


// hardware
// define HIREZ for 1600 cpi; otherwise 400 cpi
//#define HIREZ

// pins
const int led1_pin = 13; // led for blinking at startup
const int led2_pin = 13; // led for indicating mouse movement
const int clock_pin = 22; // clock output pin
//----- First sensor
//const int reset_pin = 8; // to reset ADNS
//const int select_pin = 4; // to select which sensor to read out
//----- Second sensor
const int reset_pin = 6; // to reset ADNS
const int select_pin = 10; // to select which sensor to read out
//--------------------

// serial data rate (bps)
//const int baud_rate = 250000; 
const int baud_rate = 115200;
//const int baud_rate = 9600;


//Variables

byte junk;
byte SQUAL;
byte config_bits;
byte image[900];


void setup() {
  
    // blink to indicate start of program
  pinMode(led1_pin, OUTPUT);
  digitalWrite(led1_pin, LOW);
  for (int it = 0; it < 3; it++) {
    digitalWrite(led1_pin, HIGH);
    delay(100);
    digitalWrite(led1_pin, LOW);
    delay(100);
  }
   // reset chip
   pinMode(reset_pin, OUTPUT);
   digitalWrite(reset_pin, HIGH);
   delay(100);
   digitalWrite(reset_pin, LOW);
   
  
   // set-up communication (Serial for PC; SPI for ADNS chip)
  Serial.begin(baud_rate);
  SPI.begin(select_pin);
  SPI.setBitOrder(select_pin,MSBFIRST);
  SPI.setDataMode(select_pin,SPI_MODE3);
  SPI.setClockDivider(select_pin,42); //84MHz clock on due; 2MHz on 3080);
  
  // set-up D/A converters (DAC0 and DAC1)
  analogWriteResolution(12); //12 bits on D/A (0-4096)
  
    // set cpi resolution
  #ifdef HIREZ
    delayMicroseconds(50);
    junk = SPI.transfer(select_pin,0x8a,SPI_CONTINUE);
    delayMicroseconds(50);
    config_bits = SPI.transfer(select_pin,0x19,SPI_CONTINUE);
    
    delayMicroseconds(50);
    junk = SPI.transfer(select_pin,0x0a,SPI_CONTINUE);
    delayMicroseconds(50);
    config_bits = SPI.transfer(select_pin,0x00,SPI_CONTINUE);
   #endif

}

void loop() {

  // local variables

  char c; // character input from usb serial interface

 // --- handle usb serial communication ---
    
  // if serial input is available
  if (SerialUSB.available()) {
    
    // read a single character
    c = SerialUSB.read();
    
    // if input is the request character
    if (c == 'i') {
    
    // send command to store image frame
    junk = SPI.transfer(select_pin,0x93,SPI_CONTINUE);
    delayMicroseconds(50);
    junk= SPI.transfer(select_pin,0x83,SPI_CONTINUE);
    delayMicroseconds(3000);
    
    // read image
    for (int n_pix = 0; n_pix<900; n_pix++){
      junk = SPI.transfer(select_pin,0x13,SPI_CONTINUE);
      delayMicroseconds(50);
      image[n_pix] = SPI.transfer(select_pin,0x83,SPI_CONTINUE);
      delayMicroseconds(50);
    }

    // write image to host over serial port
     SerialUSB.write(image,900);
     

     // reset chip
     pinMode(reset_pin, OUTPUT);
     digitalWrite(reset_pin, HIGH);
     delay(1);
     digitalWrite(reset_pin, LOW);
   
     #ifdef HIREZ
     delayMicroseconds(50);
     junk = SPI.transfer(select_pin,0x8a,SPI_CONTINUE);
     delayMicroseconds(50);
     config_bits = SPI.transfer(select_pin,0x19,SPI_CONTINUE);
    
     delayMicroseconds(50);
     junk = SPI.transfer(select_pin,0x0a,SPI_CONTINUE);
     delayMicroseconds(50);
     config_bits = SPI.transfer(select_pin,0x00,SPI_CONTINUE);
     #endif

    }
    else if (c == 'q') {
      
    // get SQUAL value
    junk = SPI.transfer(select_pin,0x05,SPI_CONTINUE);
    delayMicroseconds(50);
    SQUAL= SPI.transfer(select_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(50);
    
    // send SQUAL to host
    SerialUSB.write(SQUAL);
      
    }

   // otherwise ignore/discard input
 }



}
