shader_type canvas_item;
// Troca a cor de pele (tons quentes) e da roupa (cinzas) do guardião, mantendo a luz de cada
// pixel. Mesma conta de GuardiaoRosto.trocar(), que faz a cabeça.

uniform vec4 pele : source_color = vec4(0.788, 0.604, 0.447, 1.0);
uniform vec4 roupa : source_color = vec4(0.725, 0.722, 0.725, 1.0);

const vec3 PELE_BASE = vec3(0.7725, 0.6118, 0.4902);
const vec3 ROUPA_BASE = vec3(0.7255, 0.7216, 0.7255);

vec3 hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float luz(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 h = hsv(c.rgb);
	if (c.a >= 0.5 && h.z >= 0.12) {
		if (h.x >= 0.02 && h.x <= 0.11 && h.y >= 0.25 && h.z >= 0.25) {
			c.rgb = min(pele.rgb * luz(c.rgb) / luz(PELE_BASE), vec3(1.0));
		} else if (h.y < 0.25) {
			c.rgb = min(roupa.rgb * luz(c.rgb) / luz(ROUPA_BASE), vec3(1.0));
		}
	}
	COLOR = c;
}
