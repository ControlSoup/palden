#include <stdio.h>
#include <wiringPi.h>

#define LED 7 

int setup(){
  printf ("Raspberry Pi blink\n") ;
  wiringPiSetup () ;
  pinMode(LED, OUTPUT) ;
  return 0 ;
}

int update_io(){
  digitalWrite(LED, HIGH) ;	
}
