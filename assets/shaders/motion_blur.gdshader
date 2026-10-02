shader_type canvas_item;

// Radial blur from the screen centre while the player sprints: six taps on the line from each pixel to the centre, so the
// middle of the view stays sharp and the edges streak. strength 0 is the identity.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 0.5) = 0.0;

const int TAPS = 6;
// Share of a pixel's distance to the centre that the last tap reaches at strength 1.0.
const float REACH = 0.16;

void fragment() {
	vec2 to_centre = (vec2(0.5) - SCREEN_UV) * strength * REACH;
	vec3 sum = vec3(0.0);
	for (int i = 0; i < TAPS; i++) {
		sum += textureLod(screen_texture, SCREEN_UV + to_centre * (float(i) / float(TAPS - 1)), 0.0).rgb;
	}
	COLOR = vec4(sum / float(TAPS), 1.0);
}
