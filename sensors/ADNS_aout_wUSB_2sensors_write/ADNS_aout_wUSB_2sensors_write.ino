#include <SPI.h>

// spools data to Serial Monitor for testing operation
//#define SPOOL_DATA
// ----------------------------------------
// hardware

// pins
const int led1_pin = 13; // led for blinking at startup
const int led2_pin = 13; // led for indicating mouse movement
const int clock_pin = 22; // clock output pin
const int front_sensor_pin = 4; // readout pin
const int bottom_sensor_pin = 10; // readout pin


// serial data rate (bps)
const int baud_rate = 250000; 
//const int baud_rate = 115200;
//const int baud_rate = 9600;

// how often to poll ADNS motion sensor (ms)
const int poll_interval = 10;



// ----------------------------------------
// serial communicaton protocol

// request character
const char request_char = 'm';
  // reply with mouse displacement when this char received over serial

// x/y separator charactor for output
const char separator_char = ';';

// terminator character for output
const char terminator_char = '\n';


// ----------------------------------------
// clock parameters

// duration of clock high state (ms)
const int clock_tick_dur = 1;
  // attempt to set clock low again within this interval after rising edge
  // actual duration may be longer if other tasks cause delays


// ----------------------------------------
// analog output parameters

// min/max x velocity; will be mapped to min/max analog output value
const double vx_min = -127.0 / (double) poll_interval;
const double vx_max = 127.0 / (double) poll_interval;

// min/max y velocity; will be mapped to min/max analog output value
const double vy_min = -127.0 / (double) poll_interval;
const double vy_max = 127.0 / (double) poll_interval;

// mouse displacement ranges from -127 to +127 (measured)
// min/max possible velocity is therefore: (-/+) 127 / (nominal polling interval)
// actual time elapsed between polls can never be less than nominal polling interval

// DAC resolution (bits)
const int aout_res = 12;
// 12 bits for arduino due

//Variables

byte junk;
signed char x_motion;
signed char y_motion;
byte MOTION;
byte SQUAL;
String answer;
long delta_x = 0, delta_y = 0;
  // integrated mouse x/y displacement since last output over usb serial interface
  // units are mouse sensor 'dots'

signed char x_motion2;
signed char y_motion2;
byte MOTION2;
byte SQUAL2;
String answer2;
long delta_x2 = 0, delta_y2 = 0;

char reply[1000];  // serial communications reply buffer
unsigned long t_last_poll = 0;
  // time of previous mouse polling event (ms since startup)
  // measured at beginning of loop()

int led2_on = 0; // whether movement indicator led is currently on
int clock_high = 0; // whether clock is currently high


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
  
   // set-up communication (Serial for PC; SPI for ADNS chip)
  Serial.begin(baud_rate);

  // set-up D/A converters (DAC0 and DAC1)
  analogWriteResolution(12); //12 bits on D/A (0-4096)
  
  // Debug code to send min/middle/max range of analog output
  // Should not be active during behavioral experiments, as this
  // causes a long delay before the (still accumulated) movement
  // is sent to Virmen at the onset of the first trial. That is,
  // setup() seems to be called each time Virmen starts running 
  // an experiment and the delays here affect loop().
  
//  analogWrite(DAC0, 0);
//  analogWrite(DAC1, 0);
//  delay(2000);
//  analogWrite(DAC0, 2048);
//  analogWrite(DAC1, 2048);
//  delay(2000);
//  analogWrite(DAC0, 4095);
//  analogWrite(DAC1, 4095);
//  delay(2000);

}

void loop() {

  // local variables

  unsigned long t; // current time (ms since startup)
  char c; // character input from usb serial interface

  // get current time (ms)
  
  t = millis();
  
  // poll ADNS chip at specified intervals
  
  if (t - t_last_poll >= poll_interval) {

    //first sensor
    SPI.begin(front_sensor_pin);
    SPI.setBitOrder(front_sensor_pin,MSBFIRST);
    SPI.setDataMode(front_sensor_pin,SPI_MODE3);
    SPI.setClockDivider(front_sensor_pin,42); //84MHz clock on due; 2MHz on 3080);
    
    junk = SPI.transfer(front_sensor_pin,0x05,SPI_CONTINUE);
    delayMicroseconds(50);
    SQUAL= SPI.transfer(front_sensor_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(50);
    
    junk = SPI.transfer(front_sensor_pin,0x02,SPI_CONTINUE);
    delayMicroseconds(50);
    MOTION = SPI.transfer(front_sensor_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(80);
    
    junk = SPI.transfer(front_sensor_pin,0x03,SPI_CONTINUE);
    delayMicroseconds(50);
    x_motion = (signed char)SPI.transfer(front_sensor_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(50);
    
    junk = SPI.transfer(front_sensor_pin,0x04,SPI_CONTINUE);
    delayMicroseconds(50);
    y_motion = (signed char)SPI.transfer(front_sensor_pin,0x00);
    
    //analogWrite(DAC0, map(x_motion,-127,127,0,4095));
    //analogWrite(DAC1, map(y_motion,-127,127,0,4095));
    
    delta_x += x_motion;
    delta_y += y_motion;
    
    // 2nd sensor
    
    SPI.begin(bottom_sensor_pin);
    SPI.setBitOrder(bottom_sensor_pin,MSBFIRST);
    SPI.setDataMode(bottom_sensor_pin,SPI_MODE3);
    SPI.setClockDivider(bottom_sensor_pin,42); //84MHz clock on due; 2MHz on 3080);
  
    junk = SPI.transfer(bottom_sensor_pin,0x05,SPI_CONTINUE);
    delayMicroseconds(50);
    SQUAL2= SPI.transfer(bottom_sensor_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(50);
    
    junk = SPI.transfer(bottom_sensor_pin,0x02,SPI_CONTINUE);
    delayMicroseconds(50);
    MOTION2 = SPI.transfer(bottom_sensor_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(80);
    
    junk = SPI.transfer(bottom_sensor_pin,0x03,SPI_CONTINUE);
    delayMicroseconds(50);
    x_motion2 = (signed char)SPI.transfer(bottom_sensor_pin,0x00,SPI_CONTINUE);
    delayMicroseconds(50);
    
    junk = SPI.transfer(bottom_sensor_pin,0x04,SPI_CONTINUE);
    delayMicroseconds(50);
    y_motion2 = (signed char)SPI.transfer(10,0x00);
    
    analogWrite(DAC0, map(x_motion2,-127,127,0,4095));
    analogWrite(DAC1, map(y_motion2,-127,127,0,4095));
    
    delta_x2 += x_motion2;
    delta_y2 += y_motion2;
    
    
    
    // update last poll time
    t_last_poll = t;
  }
 // --- handle usb serial communication ---
    
  // if serial input is available
  if (Serial.available()) {
    
    // read a single character
    c = Serial.read();
    
    // if input is the request character
    if (c == request_char) {
      sprintf ( reply, "%d%c%d%c%d%c%d%c"
              , delta_x, separator_char
              , delta_y, separator_char
              , delta_x2, separator_char
              , delta_y2, terminator_char
              );
      Serial.write(reply);
      
      // reset integrated displacement to zero
      delta_x = 0;
      delta_y = 0;
      delta_x2 = 0;
      delta_y2 = 0;
    }

   // otherwise ignore/discard input
 }

#ifdef SPOOL_DATA  //for debugging

answer = String(MOTION) + String("     ") + String(x_motion) + String("     ") + String(y_motion) + String("     ") + String(SQUAL);
    
Serial.println(answer);

#endif


}
