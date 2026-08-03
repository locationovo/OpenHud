// Tweak.m (注入模块)
#include <stdlib.h>

__attribute__((constructor))
static void metal_hud_init(void) {
    setenv("MTL_HUD_ENABLED", "1", 1);
    setenv("MTL_HUD_LOG_ENABLED", "1", 1);
}
