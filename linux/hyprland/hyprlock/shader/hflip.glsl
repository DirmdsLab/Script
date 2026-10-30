//!HOOK MAIN
//!DESC Horizontal mirror
//!BIND HOOKED

vec4 hook()
{
    vec2 flipped_position = HOOKED_pos;
    flipped_position.x = 1.0 - flipped_position.x;
    return HOOKED_tex(flipped_position);
}
