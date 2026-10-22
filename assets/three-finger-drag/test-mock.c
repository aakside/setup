#include <assert.h>
#include <libinput.h>
struct libinput_device {unsigned vendor, product; int fingers, enabled, fail, calls;};
struct libinput_event {enum libinput_event_type type; struct libinput_device *device;};
static struct libinput_device dev;
static struct libinput_event evt;
static int pending;
void setup(unsigned v, unsigned p, int n, int fail, int type) {
 dev=(struct libinput_device){v,p,n,0,fail,0};
 evt=(struct libinput_event){type,&dev}; pending=1;
}
struct libinput_event *libinput_get_event(struct libinput *li) {(void)li; if (!pending) return 0; pending=0; return &evt;}
enum libinput_event_type libinput_event_get_type(struct libinput_event *e) {return e->type;}
struct libinput_device *libinput_event_get_device(struct libinput_event *e) {return e->device;}
unsigned libinput_device_get_id_vendor(struct libinput_device *d) {return d->vendor;}
unsigned libinput_device_get_id_product(struct libinput_device *d) {return d->product;}
int libinput_device_config_3fg_drag_get_finger_count(struct libinput_device *d) {return d->fingers;}
enum libinput_config_status libinput_device_config_3fg_drag_set_enabled(struct libinput_device *d, enum libinput_config_3fg_drag_state state) {d->calls++; if(d->fail) return LIBINPUT_CONFIG_STATUS_UNSUPPORTED; d->enabled=state; return LIBINPUT_CONFIG_STATUS_SUCCESS;}
enum libinput_config_3fg_drag_state libinput_device_config_3fg_drag_get_enabled(struct libinput_device *d) {return d->enabled;}
void check(struct libinput_event *e, int calls, int enabled) {assert(e==&evt); assert(dev.calls==calls); assert(dev.enabled==enabled);}
