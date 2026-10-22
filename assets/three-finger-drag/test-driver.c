#include <assert.h>
#include <stdio.h>
#include <libinput.h>
void setup(unsigned, unsigned, int, int, int);
void check(struct libinput_event *, int, int);
int main(void) {
 const unsigned cases[][7]={
 {0x05ac,0x0265,5,0,LIBINPUT_EVENT_DEVICE_ADDED,1,1},
 {0x004c,0x0265,5,0,LIBINPUT_EVENT_DEVICE_ADDED,1,1},
 {0x056a,0x0357,5,0,LIBINPUT_EVENT_DEVICE_ADDED,0,0},
 {0x05ac,0x030e,5,0,LIBINPUT_EVENT_DEVICE_ADDED,0,0},
 {0x05ac,0x0265,2,0,LIBINPUT_EVENT_DEVICE_ADDED,0,0},
 {0x05ac,0x0265,5,0,LIBINPUT_EVENT_POINTER_MOTION,0,0},
 {0x05ac,0x0265,5,0,LIBINPUT_EVENT_DEVICE_REMOVED,0,0},
 {0x05ac,0x0265,5,1,LIBINPUT_EVENT_DEVICE_ADDED,1,0},
 {0x05ac,0x0265,5,0,LIBINPUT_EVENT_DEVICE_ADDED,1,1}};
 for(unsigned i=0;i<sizeof(cases)/sizeof(cases[0]);i++) {
  const unsigned *c=cases[i]; setup(c[0],c[1],c[2],c[3],c[4]);
  check(libinput_get_event(NULL),c[5],c[6]); assert(libinput_get_event(NULL)==NULL);
 }
 puts("PASS: Apple USB/Bluetooth, unrelated devices, unsupported hardware, motion/removal passthrough, setter failure, reconnect, empty queue");
}
