panther main {
    // ============================================================
    // PANTHER GAME MATH MODULE
    // Vector2, Rect, Circle, Transform2D, Color, Range, Easing
    // ============================================================

    // ------------------------------------------------------------
    // Vector2
    // ------------------------------------------------------------

    struct Vector2 {
        x: float,
        y: float
    }

    fn panther_game_math_vec2(x, y) {
        return {x: x, y: y};
    }

    fn panther_game_math_vec2_zero() {
        return {x: 0.0, y: 0.0};
    }

    fn panther_game_math_vec2_one() {
        return {x: 1.0, y: 1.0};
    }

    fn panther_game_math_vec2_up() {
        return {x: 0.0, y: -1.0};
    }

    fn panther_game_math_vec2_down() {
        return {x: 0.0, y: 1.0};
    }

    fn panther_game_math_vec2_left() {
        return {x: -1.0, y: 0.0};
    }

    fn panther_game_math_vec2_right() {
        return {x: 1.0, y: 0.0};
    }

    fn panther_game_math_vec2_add(a, b) {
        return {x: a.x + b.x, y: a.y + b.y};
    }

    fn panther_game_math_vec2_sub(a, b) {
        return {x: a.x - b.x, y: a.y - b.y};
    }

    fn panther_game_math_vec2_mul(v, s) {
        return {x: v.x * s, y: v.y * s};
    }

    fn panther_game_math_vec2_multiply(a, b) {
        return {x: a.x * b.x, y: a.y * b.y};
    }

    fn panther_game_math_vec2_div(v, s) {
        if s == 0.0 {
            return {x: 0.0, y: 0.0};
        }
        let inv = pow(s, -1.0);
        return {x: v.x * inv, y: v.y * inv};
    }

    fn panther_game_math_vec2_neg(v) {
        return {x: -v.x, y: -v.y};
    }

    fn panther_game_math_vec2_dot(a, b) {
        return a.x * b.x + a.y * b.y;
    }

    fn panther_game_math_vec2_cross(a, b) {
        return a.x * b.y - a.y * b.x;
    }

    fn panther_game_math_vec2_magnitude_squared(v) {
        return v.x * v.x + v.y * v.y;
    }

    fn panther_game_math_vec2_magnitude(v) {
        return sqrt(panther_game_math_vec2_magnitude_squared(v));
    }

    fn panther_game_math_vec2_normalize(v) {
        let mag = panther_game_math_vec2_magnitude(v);
        if mag == 0.0 {
            return {x: 0.0, y: 0.0};
        }
        return panther_game_math_vec2_div(v, mag);
    }

    fn panther_game_math_vec2_distance(a, b) {
        let dx = a.x - b.x;
        let dy = a.y - b.y;
        return sqrt(dx * dx + dy * dy);
    }

    fn panther_game_math_vec2_distance_squared(a, b) {
        let dx = a.x - b.x;
        let dy = a.y - b.y;
        return dx * dx + dy * dy;
    }

    fn panther_game_math_vec2_angle(v) {
        return atan2(v.y, v.x);
    }

    fn panther_game_math_vec2_rotate(v, radians) {
        let c = cos(radians);
        let s = sin(radians);
        return {x: v.x * c - v.y * s, y: v.x * s + v.y * c};
    }

    fn panther_game_math_vec2_lerp(a, b, t) {
        let ct = 1.0 - t;
        return {x: a.x * ct + b.x * t, y: a.y * ct + b.y * t};
    }

    fn panther_game_math_vec2_lerp_unclamped(a, b, t) {
        return {x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t};
    }

    fn panther_game_math_vec2_clamp(v, min_v, max_v) {
        return {
            x: panther_game_math_clamp(v.x, min_v.x, max_v.x),
            y: panther_game_math_clamp(v.y, min_v.y, max_v.y)
        };
    }

    fn panther_game_math_vec2_min(a, b) {
        return {x: min(a.x, b.x), y: min(a.y, b.y)};
    }

    fn panther_game_math_vec2_max(a, b) {
        return {x: max(a.x, b.x), y: max(a.y, b.y)};
    }

    fn panther_game_math_vec2_sign(v) {
        return {
            x: sign(v.x),
            y: sign(v.y)
        };
    }

    fn panther_game_math_vec2_perp(v) {
        return {x: -v.y, y: v.x};
    }

    fn panther_game_math_vec2_reflect(v, normal) {
        let dot = panther_game_math_vec2_dot(v, normal);
        return {x: v.x - 2.0 * dot * normal.x, y: v.y - 2.0 * dot * normal.y};
    }

    fn panther_game_math_vec2_project(v, on_normal) {
        let dot = panther_game_math_vec2_dot(v, on_normal);
        let mag2 = panther_game_math_vec2_magnitude_squared(on_normal);
        if mag2 == 0.0 {
            return {x: 0.0, y: 0.0};
        }
        return panther_game_math_vec2_mul(on_normal, panther_game_math_div(dot, mag2));
    }

    fn panther_game_math_vec2_equals(a, b) {
        return a.x == b.x && a.y == b.y;
    }

    fn panther_game_math_vec2_to_string(v) {
        return "(" + to_string(v.x) + ", " + to_string(v.y) + ")";
    }

    // ------------------------------------------------------------
    // Rect
    // ------------------------------------------------------------

    struct Rect {
        x: float,
        y: float,
        w: float,
        h: float
    }

    fn panther_game_math_rect(x, y, w, h) {
        return {x: x, y: y, w: w, h: h};
    }

    fn panther_game_math_rect_zero() {
        return {x: 0.0, y: 0.0, w: 0.0, h: 0.0};
    }

    fn panther_game_math_rect_from_center_size(center, size) {
        return {
            x: center.x - size.x * 0.5,
            y: center.y - size.y * 0.5,
            w: size.x,
            h: size.y
        };
    }

    fn panther_game_math_rect_left(r) { return r.x; }
    fn panther_game_math_rect_right(r) { return r.x + r.w; }
    fn panther_game_math_rect_top(r) { return r.y; }
    fn panther_game_math_rect_bottom(r) { return r.y + r.h; }
    fn panther_game_math_rect_center(r) { return {x: r.x + r.w * 0.5, y: r.y + r.h * 0.5}; }
    fn panther_game_math_rect_size(r) { return {x: r.w, y: r.h}; }

    fn panther_game_math_rect_set_center(r, center) {
        return {
            x: center.x - r.w * 0.5,
            y: center.y - r.h * 0.5,
            w: r.w,
            h: r.h
        };
    }

    fn panther_game_math_rect_set_size(r, size) {
        return {x: r.x, y: r.y, w: size.x, h: size.y};
    }

    fn panther_game_math_rect_contains_point(r, p) {
        return p.x >= r.x && p.x <= r.x + r.w && p.y >= r.y && p.y <= r.y + r.h;
    }

    fn panther_game_math_rect_contains_rect(a, b) {
        return b.x >= a.x && b.x + b.w <= a.x + a.w &&
               b.y >= a.y && b.y + b.h <= a.y + a.h;
    }

    fn panther_game_math_rect_intersects(a, b) {
        return a.x < b.x + b.w && a.x + a.w > b.x &&
               a.y < b.y + b.h && a.y + a.h > b.y;
    }

    fn panther_game_math_rect_intersection(a, b) {
        let left = max(a.x, b.x);
        let top = max(a.y, b.y);
        let right = min(a.x + a.w, b.x + b.w);
        let bottom = min(a.y + a.h, b.y + b.h);

        if left >= right || top >= bottom {
            return panther_game_math_rect_zero();
        }

        return {x: left, y: top, w: right - left, h: bottom - top};
    }

    fn panther_game_math_rect_union(a, b) {
        let left = min(a.x, b.x);
        let top = min(a.y, b.y);
        let right = max(a.x + a.w, b.x + b.w);
        let bottom = max(a.y + a.h, b.y + b.h);
        return {x: left, y: top, w: right - left, h: bottom - top};
    }

    fn panther_game_math_rect_expand(r, padding) {
        return {x: r.x - padding, y: r.y - padding, w: r.w + padding * 2.0, h: r.h + padding * 2.0};
    }

    fn panther_game_math_rect_expand_symmetric(r, h_padding, v_padding) {
        return {x: r.x - h_padding, y: r.y - v_padding, w: r.w + h_padding * 2.0, h: r.h + v_padding * 2.0};
    }

    fn panther_game_math_rect_clamp(r, bounds) {
        let nx = panther_game_math_clamp(r.x, bounds.x, bounds.x + bounds.w - r.w);
        let ny = panther_game_math_clamp(r.y, bounds.y, bounds.y + bounds.h - r.h);
        return {x: nx, y: ny, w: r.w, h: r.h};
    }

    fn panther_game_math_rect_equals(a, b) {
        return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
    }

    fn panther_game_math_rect_to_string(r) {
        return "Rect(" + to_string(r.x) + ", " + to_string(r.y) + ", " + to_string(r.w) + ", " + to_string(r.h) + ")";
    }

    // ------------------------------------------------------------
    // Circle
    // ------------------------------------------------------------

    struct Circle {
        x: float,
        y: float,
        r: float
    }

    fn panther_game_math_circle(x, y, r) {
        return {x: x, y: y, r: r};
    }

    fn panther_game_math_circle_from_center(center, radius) {
        return {x: center.x, y: center.y, r: radius};
    }

    fn panther_game_math_circle_center(c) {
        return {x: c.x, y: c.y};
    }

    fn panther_game_math_circle_contains_point(c, p) {
        let dx = p.x - c.x;
        let dy = p.y - c.y;
        return dx * dx + dy * dy <= c.r * c.r;
    }

    fn panther_game_math_circle_intersects(a, b) {
        let dx = a.x - b.x;
        let dy = a.y - b.y;
        let dist_sq = dx * dx + dy * dy;
        let r_sum = a.r + b.r;
        return dist_sq <= r_sum * r_sum;
    }

    fn panther_game_math_circle_intersection(a, b) {
        if !panther_game_math_circle_intersects(a, b) {
            return {x: 0.0, y: 0.0, r: 0.0};
        }
        if a.r < b.r { return a; }
        return b;
    }

    fn panther_game_math_circle_union(a, b) {
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let d = sqrt(dx * dx + dy * dy);

        if d <= abs(a.r - b.r) {
            if a.r >= b.r { return a; }
            return b;
        }

        let r = (d + a.r + b.r) * 0.5;
        let cx = a.x + panther_game_math_div(dx, d) * (r - a.r);
        let cy = a.y + panther_game_math_div(dy, d) * (r - a.r);
        return {x: cx, y: cy, r: r};
    }

    fn panther_game_math_circle_equals(a, b) {
        return a.x == b.x && a.y == b.y && a.r == b.r;
    }

    fn panther_game_math_circle_to_string(c) {
        return "Circle(" + to_string(c.x) + ", " + to_string(c.y) + ", " + to_string(c.r) + ")";
    }

    // ------------------------------------------------------------
    // Transform2D
    // ------------------------------------------------------------

    struct Transform2D {
        pos: Vector2,
        rot: float,
        scale: Vector2
    }

    fn panther_game_math_transform_identity() {
        return {pos: panther_game_math_vec2_zero(), rot: 0.0, scale: panther_game_math_vec2_one()};
    }

    fn panther_game_math_transform_translate(t, v) {
        return {pos: panther_game_math_vec2_add(t.pos, v), rot: t.rot, scale: t.scale};
    }

    fn panther_game_math_transform_rotate(t, radians) {
        return {pos: t.pos, rot: t.rot + radians, scale: t.scale};
    }

    fn panther_game_math_transform_scale(t, s) {
        return {pos: t.pos, rot: t.rot, scale: panther_game_math_vec2_multiply(t.scale, s)};
    }

    fn panther_game_math_transform_compose(a, b) {
        let pos = panther_game_math_vec2_add(panther_game_math_vec2_rotate(panther_game_math_vec2_multiply(b.pos, a.scale), a.rot), a.pos);
        let rot = a.rot + b.rot;
        let scale = panther_game_math_vec2_multiply(a.scale, b.scale);
        return {pos: pos, rot: rot, scale: scale};
    }

    fn panther_game_math_transform_inverse(t) {
        let inv_scale = {x: pow(t.scale.x, -1.0), y: pow(t.scale.y, -1.0)};
        let inv_rot = -t.rot;
        let c = cos(inv_rot);
        let s = sin(inv_rot);
        let inv_pos_x = -(t.pos.x * c - t.pos.y * s) * inv_scale.x;
        let inv_pos_y = -(t.pos.x * s + t.pos.y * c) * inv_scale.y;
        return {pos: {x: inv_pos_x, y: inv_pos_y}, rot: inv_rot, scale: inv_scale};
    }

    fn panther_game_math_transform_point(t, p) {
        let scaled = panther_game_math_vec2_multiply(p, t.scale);
        let rotated = panther_game_math_vec2_rotate(scaled, t.rot);
        return panther_game_math_vec2_add(rotated, t.pos);
    }

    fn panther_game_math_transform_vector(t, v) {
        let scaled = panther_game_math_vec2_multiply(v, t.scale);
        return panther_game_math_vec2_rotate(scaled, t.rot);
    }

    fn panther_game_math_transform_direction(t, v) {
        let rotated = panther_game_math_vec2_rotate(v, t.rot);
        return panther_game_math_vec2_multiply(rotated, t.scale);
    }

    fn panther_game_math_transform_to_matrix(t) {
        let c = cos(t.rot);
        let s = sin(t.rot);
        let a = c * t.scale.x;
        let b = s * t.scale.x;
        let c_val = -s * t.scale.y;
        let d = c * t.scale.y;
        let e = t.pos.x;
        let f = t.pos.y;
        return [a, b, 0.0, c_val, d, 0.0, e, f, 1.0];
    }

    // ------------------------------------------------------------
    // GameColor
    // ------------------------------------------------------------

    struct GameColor {
        r: float,
        g: float,
        b: float,
        a: float
    }

    fn panther_game_math_color(r, g, b, a) {
        return {
            r: panther_game_math_clamp(r, 0.0, 1.0),
            g: panther_game_math_clamp(g, 0.0, 1.0),
            b: panther_game_math_clamp(b, 0.0, 1.0),
            a: panther_game_math_clamp(a, 0.0, 1.0)
        };
    }

    fn panther_game_math_color_rgb(r, g, b) {
        return panther_game_math_color(r, g, b, 1.0);
    }

    fn panther_game_math_color_rgba(r, g, b, a) {
        return panther_game_math_color(r, g, b, a);
    }

    fn panther_game_math_color_hex(hex) {
        // Simple hex parsing - return white as placeholder
        return {r: 1.0, g: 1.0, b: 1.0, a: 1.0};
    }

    fn panther_game_math_color_white() { return {r: 1.0, g: 1.0, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_black() { return {r: 0.0, g: 0.0, b: 0.0, a: 1.0}; }
    fn panther_game_math_color_red() { return {r: 1.0, g: 0.0, b: 0.0, a: 1.0}; }
    fn panther_game_math_color_green() { return {r: 0.0, g: 1.0, b: 0.0, a: 1.0}; }
    fn panther_game_math_color_blue() { return {r: 0.0, g: 0.0, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_yellow() { return {r: 1.0, g: 1.0, b: 0.0, a: 1.0}; }
    fn panther_game_math_color_cyan() { return {r: 0.0, g: 1.0, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_magenta() { return {r: 1.0, g: 0.0, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_gray() { return {r: 0.5, g: 0.5, b: 0.5, a: 1.0}; }
    fn panther_game_math_color_clear() { return {r: 0.0, g: 0.0, b: 0.0, a: 0.0}; }

    fn panther_game_math_color_panther_blue() { return {r: 0.0, g: 0.4, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_panther_dark_blue() { return {r: 0.0, g: 0.2, b: 0.6, a: 1.0}; }
    fn panther_game_math_color_panther_light_blue() { return {r: 0.4, g: 0.67, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_panther_neon() { return {r: 0.0, g: 1.0, b: 1.0, a: 1.0}; }
    fn panther_game_math_color_panther_dark() { return {r: 0.04, g: 0.06, b: 0.1, a: 1.0}; }
    fn panther_game_math_color_panther_grid() { return {r: 0.1, g: 0.16, b: 0.23, a: 1.0}; }

    fn panther_game_math_color_lerp(a, b, t) {
        let ct = 1.0 - t;
        return {
            r: a.r * ct + b.r * t,
            g: a.g * ct + b.g * t,
            b: a.b * ct + b.b * t,
            a: a.a * ct + b.a * t
        };
    }

    fn panther_game_math_color_mul(c, s) {
        return {r: c.r * s, g: c.g * s, b: c.b * s, a: c.a};
    }

    fn panther_game_math_color_add(a, b) {
        return {
            r: panther_game_math_clamp(a.r + b.r, 0.0, 1.0),
            g: panther_game_math_clamp(a.g + b.g, 0.0, 1.0),
            b: panther_game_math_clamp(a.b + b.b, 0.0, 1.0),
            a: panther_game_math_clamp(a.a + b.a, 0.0, 1.0)
        };
    }

    fn panther_game_math_color_to_string(c) {
        let r = to_int(c.r * 255.0);
        let g = to_int(c.g * 255.0);
        let b = to_int(c.b * 255.0);
        let a = to_int(c.a * 255.0);
        return "rgba(" + to_string(r) + ", " + to_string(g) + ", " + to_string(b) + ", " + to_string(a / 255.0) + ")";
    }

    fn panther_game_math_color_equals(a, b) {
        return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
    }

    // ------------------------------------------------------------
    // Range
    // ------------------------------------------------------------

    struct Range {
        min: float,
        max: float
    }

    fn panther_game_math_range(min, max) {
        if min > max { return {min: max, max: min}; }
        return {min: min, max: max};
    }

    fn panther_game_math_range_zero() { return {min: 0.0, max: 0.0}; }
    fn panther_game_math_range_one() { return {min: 0.0, max: 1.0}; }

    fn panther_game_math_range_contains(r, v) { return v >= r.min && v <= r.max; }
    fn panther_game_math_range_clamp(r, v) { return panther_game_math_clamp(v, r.min, r.max); }
    fn panther_game_math_range_lerp(r, t) { return r.min + (r.max - r.min) * panther_game_math_clamp(t, 0.0, 1.0); }
    fn panther_game_math_range_size(r) { return r.max - r.min; }
    fn panther_game_math_range_center(r) { return (r.min + r.max) * 0.5; }

    fn panther_game_math_range_expand(r, amount) {
        return {min: r.min - amount, max: r.max + amount};
    }

    fn panther_game_math_range_intersect(a, b) {
        let mn = max(a.min, b.min);
        let mx = min(a.max, b.max);
        if mn > mx { return panther_game_math_range_zero(); }
        return {min: mn, max: mx};
    }

    fn panther_game_math_range_union(a, b) {
        return {min: min(a.min, b.min), max: max(a.max, b.max)};
    }

    // ------------------------------------------------------------
    // Easing Functions
    // ------------------------------------------------------------

    fn panther_game_math_ease_linear(t) { return panther_game_math_clamp(t, 0.0, 1.0); }

    fn panther_game_math_ease_in_quad(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return ct * ct; }
    fn panther_game_math_ease_out_quad(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return 1.0 - (1.0 - ct) * (1.0 - ct); }
    fn panther_game_math_ease_in_out_quad(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct < 0.5 { return 2.0 * ct * ct; }
        return 1.0 - pow(-2.0 * ct + 2.0, 2.0) * 0.5;
    }

    fn panther_game_math_ease_in_cubic(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return ct * ct * ct; }
    fn panther_game_math_ease_out_cubic(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return 1.0 - pow(1.0 - ct, 3.0); }
    fn panther_game_math_ease_in_out_cubic(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct < 0.5 { return 4.0 * ct * ct * ct; }
        return 1.0 - pow(-2.0 * ct + 2.0, 3.0) * 0.5;
    }

    fn panther_game_math_ease_in_quart(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return ct * ct * ct * ct; }
    fn panther_game_math_ease_out_quart(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return 1.0 - pow(1.0 - ct, 4.0); }
    fn panther_game_math_ease_in_out_quart(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct < 0.5 { return 8.0 * ct * ct * ct * ct; }
        return 1.0 - pow(-2.0 * ct + 2.0, 4.0) * 0.5;
    }

    fn panther_game_math_ease_in_quint(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return ct * ct * ct * ct * ct; }
    fn panther_game_math_ease_out_quint(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return 1.0 - pow(1.0 - ct, 5.0); }
    fn panther_game_math_ease_in_out_quint(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct < 0.5 { return 16.0 * ct * ct * ct * ct * ct; }
        return 1.0 - pow(-2.0 * ct + 2.0, 5.0) * 0.5;
    }

    fn panther_game_math_ease_in_sine(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return 1.0 - cos(ct * 1.57079632679); }
    fn panther_game_math_ease_out_sine(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return sin(ct * 1.57079632679); }
    fn panther_game_math_ease_in_out_sine(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return -(cos(3.14159265359 * ct) - 1.0) * 0.5; }

    fn panther_game_math_ease_in_expo(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct == 0.0 { return 0.0; }
        return pow(2.0, 10.0 * (ct - 1.0));
    }
    fn panther_game_math_ease_out_expo(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct == 1.0 { return 1.0; }
        return 1.0 - pow(2.0, -10.0 * ct);
    }
    fn panther_game_math_ease_in_out_expo(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct == 0.0 { return 0.0; }
        if ct == 1.0 { return 1.0; }
        if ct < 0.5 { return pow(2.0, 20.0 * ct - 10.0) * 0.5; }
        return (2.0 - pow(2.0, -20.0 * ct + 10.0)) * 0.5;
    }

    fn panther_game_math_ease_in_circ(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return 1.0 - sqrt(1.0 - ct * ct); }
    fn panther_game_math_ease_out_circ(t) { let ct = panther_game_math_clamp(t, 0.0, 1.0); return sqrt(1.0 - pow(ct - 1.0, 2.0)); }
    fn panther_game_math_ease_in_out_circ(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct < 0.5 { return (1.0 - sqrt(1.0 - pow(2.0 * ct, 2.0))) * 0.5; }
        return (sqrt(1.0 - pow(-2.0 * ct + 2.0, 2.0)) + 1.0) * 0.5;
    }

    fn panther_game_math_ease_in_back(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        let c1 = 1.70158;
        let c3 = c1 + 1.0;
        return c3 * ct * ct * ct - c1 * ct * ct;
    }
    fn panther_game_math_ease_out_back(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        let c1 = 1.70158;
        let c3 = c1 + 1.0;
        return 1.0 + c3 * pow(ct - 1.0, 3.0) + c1 * pow(ct - 1.0, 2.0);
    }
    fn panther_game_math_ease_in_out_back(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        let c1 = 1.70158;
        let c2 = c1 * 1.525;
        if ct < 0.5 { return (pow(2.0 * ct, 2.0) * ((c2 + 1.0) * 2.0 * ct - c2)) * 0.5; }
        return (pow(2.0 * ct - 2.0, 2.0) * ((c2 + 1.0) * (ct * 2.0 - 2.0) + c2) + 2.0) * 0.5;
    }

    fn panther_game_math_ease_in_elastic(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct == 0.0 { return 0.0; }
        if ct == 1.0 { return 1.0; }
        return -pow(2.0, 10.0 * ct - 10.0) * sin((ct * 10.0 - 10.75) * 6.28318530718 * 0.3333333);
    }
    fn panther_game_math_ease_out_elastic(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct == 0.0 { return 0.0; }
        if ct == 1.0 { return 1.0; }
        return pow(2.0, -10.0 * ct) * sin((ct * 10.0 - 0.75) * 6.28318530718 * 0.3333333) + 1.0;
    }
    fn panther_game_math_ease_in_out_elastic(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct == 0.0 { return 0.0; }
        if ct == 1.0 { return 1.0; }
        if ct < 0.5 {
            return -(pow(2.0, 20.0 * ct - 10.0) * sin((20.0 * ct - 11.125) * 6.28318530718 * 0.2222222)) * 0.5;
        }
        return pow(2.0, -20.0 * ct + 10.0) * sin((20.0 * ct - 11.125) * 6.28318530718 * 0.2222222) * 0.5 + 1.0;
    }

    fn panther_game_math_ease_in_bounce(t) { return 1.0 - panther_game_math_ease_out_bounce(1.0 - panther_game_math_clamp(t, 0.0, 1.0)); }
    fn panther_game_math_ease_out_bounce(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        let n1 = 7.5625;
        let d1 = 2.75;
        let d1_inv = pow(d1, -1.0);
        if ct < 1.0 * d1_inv { return n1 * ct * ct; }
        elif ct < 2.0 * d1_inv { let pv = ct - 1.5 * d1_inv; return n1 * pv * pv + 0.75; }
        elif ct < 2.5 * d1_inv { let pv2 = ct - 2.25 * d1_inv; return n1 * pv2 * pv2 + 0.9375; }
        else { let pv3 = ct - 2.625 * d1_inv; return n1 * pv3 * pv3 + 0.984375; }
    }
    fn panther_game_math_ease_in_out_bounce(t) {
        let ct = panther_game_math_clamp(t, 0.0, 1.0);
        if ct < 0.5 { return panther_game_math_ease_in_bounce(ct * 2.0) * 0.5; }
        return panther_game_math_ease_out_bounce(ct * 2.0 - 1.0) * 0.5 + 0.5;
    }

    // ------------------------------------------------------------
    // Math utilities
    // ------------------------------------------------------------

    fn panther_game_math_clamp(v, min_v, max_v) {
        if v < min_v { return min_v; }
        if v > max_v { return max_v; }
        return v;
    }

    fn panther_game_math_min(a, b) { if a < b { return a; } return b; }
    fn panther_game_math_max(a, b) { if a > b { return a; } return b; }
    fn panther_game_math_abs(x) { if x < 0 { return -x; } return x; }
    fn panther_game_math_sign(x) { if x > 0 { return 1; } if x < 0 { return -1; } return 0; }
    fn panther_game_math_sqrt(x) { return x ** 0.5; }
    fn panther_game_math_pow(base, exp) { return base ** exp; }
    fn panther_game_math_div(x, y) { return x * pow(y, -1.0); }
    fn panther_game_math_cos(x) { return cos(x); }
    fn panther_game_math_sin(x) { return sin(x); }
    fn panther_game_math_atan2(y, x) {
        let ratio = panther_game_math_div(y, x);
        if x > 0 { return panther_game_math_atan(ratio); }
        if x < 0 && y >= 0 { return panther_game_math_atan(ratio) + 3.14159265359; }
        if x < 0 && y < 0 { return panther_game_math_atan(ratio) - 3.14159265359; }
        if x == 0 && y > 0 { return 1.57079632679; }
        if x == 0 && y < 0 { return -1.57079632679; }
        return 0;
    }
    fn panther_game_math_atan(x) {
        if x == 0 { return 0; }
        if panther_game_math_abs(x) == 1 { return x * 0.785398163397; }
        if panther_game_math_abs(x) > 1 { return 1.57079632679 - panther_game_math_atan(panther_game_math_div(1, x)); }
        let x2 = x * x;
        let result = x;
        let term = x;
        for i in 1..50 {
            term = -term * x2 * panther_game_math_div(2 * i - 1, 2 * i + 1);
            result = result + term;
            if panther_game_math_abs(term) < 0.000000000001 { break; }
        }
        return result;
    }
    fn panther_game_math_tan(x) { return panther_game_math_div(panther_game_math_sin(x), panther_game_math_cos(x)); }

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    fn panther_game_clock_create() {
        let now = time();
        return {start: now, last: now, paused: false, pause_start: 0.0, pause_total: 0.0};
    }

    fn panther_game_clock_elapsed(clk) {
        let now = time();
        let extra = 0.0;
        if clk.paused { extra = now - clk.pause_start; }
        return now - clk.start - (clk.pause_total + extra);
    }

    fn panther_game_clock_delta(clk) {
        let now = time();
        return now - clk.last;
    }

    fn panther_game_clock_tick(clk) {
        let now = time();
        return {start: clk.start, last: now, paused: clk.paused, pause_start: clk.pause_start, pause_total: clk.pause_total};
    }

    fn panther_game_clock_reset(clk) {
        let now = time();
        return {start: now, last: now, paused: false, pause_start: 0.0, pause_total: 0.0};
    }

    fn panther_game_clock_pause(clk) {
        let now = time();
        return {start: clk.start, last: clk.last, paused: true, pause_start: now, pause_total: clk.pause_total};
    }

    fn panther_game_clock_resume(clk) {
        let now = time();
        if !clk.paused { return clk; }
        let added = now - clk.pause_start;
        return {start: clk.start, last: now, paused: false, pause_start: 0.0, pause_total: clk.pause_total + added};
    }

    fn panther_game_clock_is_paused(clk) { return clk.paused; }

    // ------------------------------------------------------------
    // Game Loop
    // ------------------------------------------------------------

    fn panther_game_loop_create(fps) {
        let now = time();
        return {
            state: "stopped",
            target_fps: fps,
            frame_duration: panther_game_math_div(1.0, fps),
            last_frame_time: now,
            frame_count: 0,
            delta: 0.0,
            elapsed: 0.0,
            max_delta: 0.1,
            start_time: now,
            pause_start: 0,
            paused_duration: 0.0,
            fps_timer: 0.0,
            fps_count: 0,
            actual_fps: 0.0,
            dropped_count: 0
        };
    }

    fn panther_game_loop_start(gl) {
        if gl.state != "stopped" { return gl; }
        let now = time();
        return {
            state: "running",
            target_fps: gl.target_fps,
            frame_duration: gl.frame_duration,
            last_frame_time: now,
            frame_count: 0,
            delta: 0.0,
            elapsed: 0.0,
            max_delta: gl.max_delta,
            start_time: now,
            pause_start: 0.0,
            paused_duration: 0.0,
            fps_timer: 0.0,
            fps_count: 0,
            actual_fps: 0.0,
            dropped_count: 0
        };
    }

    fn panther_game_loop_try_start(gl) {
        return gl.state == "stopped";
    }

    fn panther_game_loop_stop(gl) {
        if gl.state == "stopped" { return gl; }
        return {
            state: "stopped",
            target_fps: gl.target_fps,
            frame_duration: gl.frame_duration,
            last_frame_time: gl.last_frame_time,
            frame_count: gl.frame_count,
            delta: 0.0,
            elapsed: gl.elapsed,
            max_delta: gl.max_delta,
            start_time: gl.start_time,
            pause_start: 0.0,
            paused_duration: gl.paused_duration,
            fps_timer: gl.fps_timer,
            fps_count: gl.fps_count,
            actual_fps: gl.actual_fps,
            dropped_count: gl.dropped_count
        };
    }

    fn panther_game_loop_try_stop(gl) {
        return gl.state != "stopped";
    }

    fn panther_game_loop_pause(gl) {
        if gl.state != "running" { return gl; }
        let now = time();
        return {
            state: "paused",
            target_fps: gl.target_fps,
            frame_duration: gl.frame_duration,
            last_frame_time: gl.last_frame_time,
            frame_count: gl.frame_count,
            delta: gl.delta,
            elapsed: gl.elapsed,
            max_delta: gl.max_delta,
            start_time: gl.start_time,
            pause_start: now,
            paused_duration: gl.paused_duration,
            fps_timer: gl.fps_timer,
            fps_count: gl.fps_count,
            actual_fps: gl.actual_fps,
            dropped_count: gl.dropped_count
        };
    }

    fn panther_game_loop_try_pause(gl) {
        return gl.state == "running";
    }

    fn panther_game_loop_resume(gl) {
        if gl.state != "paused" { return gl; }
        let now = time();
        let extra_pause = now - gl.pause_start;
        return {
            state: "running",
            target_fps: gl.target_fps,
            frame_duration: gl.frame_duration,
            last_frame_time: now,
            frame_count: gl.frame_count,
            delta: gl.delta,
            elapsed: gl.elapsed,
            max_delta: gl.max_delta,
            start_time: gl.start_time,
            pause_start: 0.0,
            paused_duration: gl.paused_duration + extra_pause,
            fps_timer: gl.fps_timer,
            fps_count: gl.fps_count,
            actual_fps: gl.actual_fps,
            dropped_count: gl.dropped_count
        };
    }

    fn panther_game_loop_try_resume(gl) {
        return gl.state == "paused";
    }

    fn panther_game_loop_is_running(gl) { return gl.state == "running"; }
    fn panther_game_loop_is_paused(gl) { return gl.state == "paused"; }
    fn panther_game_loop_is_stopped(gl) { return gl.state == "stopped"; }

    fn panther_game_loop_frame_count(gl) { return gl.frame_count; }
    fn panther_game_loop_delta_time(gl) { return gl.delta; }
    fn panther_game_loop_elapsed(gl) { return gl.elapsed; }
    fn panther_game_loop_actual_fps(gl) { return gl.actual_fps; }
    fn panther_game_loop_target_fps(gl) { return gl.target_fps; }
    fn panther_game_loop_dropped_frames(gl) { return gl.dropped_count; }

    fn panther_game_loop_update(gl) {
        if gl.state != "running" { return gl; }
        let now = time();
        let raw_dt = now - gl.last_frame_time;
        let clamped_dt = raw_dt;
        let new_dropped = gl.dropped_count;

        if raw_dt > gl.max_delta {
            new_dropped = new_dropped + 1;
            clamped_dt = gl.max_delta;
        }

        let new_count = gl.frame_count + 1;
        let new_elapsed = gl.elapsed + clamped_dt;
        let new_fps_timer = gl.fps_timer + clamped_dt;
        let new_fps_count = gl.fps_count + 1;
        let new_actual_fps = gl.actual_fps;

        if new_fps_timer >= 1.0 {
            new_actual_fps = panther_game_math_div(new_fps_count, new_fps_timer);
            new_fps_timer = 0.0;
            new_fps_count = 0;
        }

        if clamped_dt > gl.frame_duration {
            let catch_frames = floor(panther_game_math_div(clamped_dt, gl.frame_duration));
            if catch_frames > 1 {
                new_dropped = new_dropped + (catch_frames - 1);
            }
        }

        return {
            state: "running",
            target_fps: gl.target_fps,
            frame_duration: gl.frame_duration,
            last_frame_time: now,
            frame_count: new_count,
            delta: clamped_dt,
            elapsed: new_elapsed,
            max_delta: gl.max_delta,
            start_time: gl.start_time,
            pause_start: 0.0,
            paused_duration: gl.paused_duration,
            fps_timer: new_fps_timer,
            fps_count: new_fps_count,
            actual_fps: new_actual_fps,
            dropped_count: new_dropped
        };
    }

    fn panther_game_loop_updated(gl) {
        return panther_game_loop_update(gl);
    }

    fn panther_game_loop_set_max_delta(gl, max_dt) {
        return {
            state: gl.state,
            target_fps: gl.target_fps,
            frame_duration: gl.frame_duration,
            last_frame_time: gl.last_frame_time,
            frame_count: gl.frame_count,
            delta: gl.delta,
            elapsed: gl.elapsed,
            max_delta: max_dt,
            start_time: gl.start_time,
            pause_start: gl.pause_start,
            paused_duration: gl.paused_duration,
            fps_timer: gl.fps_timer,
            fps_count: gl.fps_count,
            actual_fps: gl.actual_fps,
            dropped_count: gl.dropped_count
        };
    }

    fn panther_game_loop_get_max_delta(gl) { return gl.max_delta; }

    // ------------------------------------------------------------
    // Input System
    // ------------------------------------------------------------

    fn panther_game_input_array_contains(arr, item) {
        for i in 0..len(arr)-1 {
            if arr[i] == item { return true; }
        }
        return false;
    }

    fn panther_game_input_array_remove(arr, item) {
        let result = [];
        for i in 0..len(arr)-1 {
            if arr[i] != item {
                result = array_push(result, arr[i]);
            }
        }
        return result;
    }

    fn panther_game_input_create() {
        return {
            keys_down: [],
            keys_pressed: [],
            keys_released: [],
            mouse_x: 0.0,
            mouse_y: 0.0,
            mouse_down: [],
            mouse_pressed: [],
            mouse_released: [],
            actions: [],
            touch_active: false,
            touch_x: 0.0,
            touch_y: 0.0
        };
    }

    fn panther_game_input_key_down(inp, key) {
        return panther_game_input_array_contains(inp.keys_down, key);
    }

    fn panther_game_input_key_pressed(inp, key) {
        return panther_game_input_array_contains(inp.keys_pressed, key);
    }

    fn panther_game_input_key_released(inp, key) {
        return panther_game_input_array_contains(inp.keys_released, key);
    }

    fn panther_game_input_any_key_down(inp, keys) {
        for i in 0..len(keys)-1 {
            if panther_game_input_key_down(inp, keys[i]) { return true; }
        }
        return false;
    }

    fn panther_game_input_mouse_position(inp) {
        return {x: inp.mouse_x, y: inp.mouse_y};
    }

    fn panther_game_input_mouse_down(inp, button) {
        return panther_game_input_array_contains(inp.mouse_down, button);
    }

    fn panther_game_input_mouse_pressed(inp, button) {
        return panther_game_input_array_contains(inp.mouse_pressed, button);
    }

    fn panther_game_input_mouse_released(inp, button) {
        return panther_game_input_array_contains(inp.mouse_released, button);
    }

    fn panther_game_input_touch_position(inp) {
        return {x: inp.touch_x, y: inp.touch_y};
    }

    fn panther_game_input_touch_active(inp) {
        return inp.touch_active;
    }

    fn panther_game_input_add_action(inp, name, keys) {
        let new_actions = array_push(inp.actions, {name: name, keys: keys});
        return {
            keys_down: inp.keys_down,
            keys_pressed: inp.keys_pressed,
            keys_released: inp.keys_released,
            mouse_x: inp.mouse_x,
            mouse_y: inp.mouse_y,
            mouse_down: inp.mouse_down,
            mouse_pressed: inp.mouse_pressed,
            mouse_released: inp.mouse_released,
            actions: new_actions,
            touch_active: inp.touch_active,
            touch_x: inp.touch_x,
            touch_y: inp.touch_y
        };
    }

    fn panther_game_input_get_action_keys(inp, name) {
        for i in 0..len(inp.actions)-1 {
            if inp.actions[i].name == name {
                return inp.actions[i].keys;
            }
        }
        return [];
    }

    fn panther_game_input_action(inp, name) {
        let action_keys = panther_game_input_get_action_keys(inp, name);
        return panther_game_input_any_key_down(inp, action_keys);
    }

    fn panther_game_input_action_pressed(inp, name) {
        let action_keys = panther_game_input_get_action_keys(inp, name);
        for i in 0..len(action_keys)-1 {
            if panther_game_input_key_pressed(inp, action_keys[i]) { return true; }
        }
        return false;
    }

    fn panther_game_input_action_released(inp, name) {
        let action_keys = panther_game_input_get_action_keys(inp, name);
        for i in 0..len(action_keys)-1 {
            if panther_game_input_key_released(inp, action_keys[i]) { return true; }
        }
        return false;
    }

    fn panther_game_input_process_event(inp, event) {
        let etype = event.type;

        // Key down event
        if etype == "keydown" {
            let ekey = event.key;
            if !panther_game_input_array_contains(inp.keys_down, ekey) {
                let new_keys_down = array_push(inp.keys_down, ekey);
                let new_keys_pressed = array_push(inp.keys_pressed, ekey);
                return {
                    keys_down: new_keys_down,
                    keys_pressed: new_keys_pressed,
                    keys_released: inp.keys_released,
                    mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                    mouse_down: inp.mouse_down,
                    mouse_pressed: inp.mouse_pressed,
                    mouse_released: inp.mouse_released,
                    actions: inp.actions,
                    touch_active: inp.touch_active,
                    touch_x: inp.touch_x, touch_y: inp.touch_y
                };
            }
            return inp;
        }

        // Key up event
        if etype == "keyup" {
            let ekey = event.key;
            let new_keys_down = panther_game_input_array_remove(inp.keys_down, ekey);
            let new_keys_released = array_push(inp.keys_released, ekey);
            return {
                keys_down: new_keys_down,
                keys_pressed: inp.keys_pressed,
                keys_released: new_keys_released,
                mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                mouse_down: inp.mouse_down,
                mouse_pressed: inp.mouse_pressed,
                mouse_released: inp.mouse_released,
                actions: inp.actions,
                touch_active: inp.touch_active,
                touch_x: inp.touch_x, touch_y: inp.touch_y
            };
        }

        // Mouse move event
        if etype == "mousemove" {
            return {
                keys_down: inp.keys_down,
                keys_pressed: inp.keys_pressed,
                keys_released: inp.keys_released,
                mouse_x: event.x, mouse_y: event.y,
                mouse_down: inp.mouse_down,
                mouse_pressed: inp.mouse_pressed,
                mouse_released: inp.mouse_released,
                actions: inp.actions,
                touch_active: inp.touch_active,
                touch_x: inp.touch_x, touch_y: inp.touch_y
            };
        }

        // Mouse down event
        if etype == "mousedown" {
            let btn = event.button;
            if !panther_game_input_array_contains(inp.mouse_down, btn) {
                let new_mouse_down = array_push(inp.mouse_down, btn);
                let new_mouse_pressed = array_push(inp.mouse_pressed, btn);
                return {
                    keys_down: inp.keys_down,
                    keys_pressed: inp.keys_pressed,
                    keys_released: inp.keys_released,
                    mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                    mouse_down: new_mouse_down,
                    mouse_pressed: new_mouse_pressed,
                    mouse_released: inp.mouse_released,
                    actions: inp.actions,
                    touch_active: inp.touch_active,
                    touch_x: inp.touch_x, touch_y: inp.touch_y
                };
            }
            return inp;
        }

        // Mouse up event
        if etype == "mouseup" {
            let btn = event.button;
            let new_mouse_down = panther_game_input_array_remove(inp.mouse_down, btn);
            let new_mouse_released = array_push(inp.mouse_released, btn);
            return {
                keys_down: inp.keys_down,
                keys_pressed: inp.keys_pressed,
                keys_released: inp.keys_released,
                mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                mouse_down: new_mouse_down,
                mouse_pressed: inp.mouse_pressed,
                mouse_released: new_mouse_released,
                actions: inp.actions,
                touch_active: inp.touch_active,
                touch_x: inp.touch_x, touch_y: inp.touch_y
            };
        }

        // Touch event
        if etype == "touchstart" || etype == "touchmove" {
            return {
                keys_down: inp.keys_down,
                keys_pressed: inp.keys_pressed,
                keys_released: inp.keys_released,
                mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                mouse_down: inp.mouse_down,
                mouse_pressed: inp.mouse_pressed,
                mouse_released: inp.mouse_released,
                actions: inp.actions,
                touch_active: true,
                touch_x: event.x, touch_y: event.y
            };
        }

        if etype == "touchend" {
            return {
                keys_down: inp.keys_down,
                keys_pressed: inp.keys_pressed,
                keys_released: inp.keys_released,
                mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                mouse_down: inp.mouse_down,
                mouse_pressed: inp.mouse_pressed,
                mouse_released: inp.mouse_released,
                actions: inp.actions,
                touch_active: false,
                touch_x: inp.touch_x, touch_y: inp.touch_y
            };
        }

        // Focus lost — reset all keys
        if etype == "focus_lost" {
            return {
                keys_down: [],
                keys_pressed: [],
                keys_released: inp.keys_released,
                mouse_x: inp.mouse_x, mouse_y: inp.mouse_y,
                mouse_down: [],
                mouse_pressed: [],
                mouse_released: inp.mouse_released,
                actions: inp.actions,
                touch_active: false,
                touch_x: 0.0, touch_y: 0.0
            };
        }

        return inp;
    }

    fn panther_game_input_end_frame(inp) {
        return {
            keys_down: inp.keys_down,
            keys_pressed: [],
            keys_released: [],
            mouse_x: inp.mouse_x,
            mouse_y: inp.mouse_y,
            mouse_down: inp.mouse_down,
            mouse_pressed: [],
            mouse_released: [],
            actions: inp.actions,
            touch_active: inp.touch_active,
            touch_x: inp.touch_x,
            touch_y: inp.touch_y
        };
    }

    fn panther_game_input_focus_lost(inp) {
        return {
            keys_down: [],
            keys_pressed: [],
            keys_released: [],
            mouse_x: inp.mouse_x,
            mouse_y: inp.mouse_y,
            mouse_down: [],
            mouse_pressed: [],
            mouse_released: [],
            actions: inp.actions,
            touch_active: false,
            touch_x: 0.0,
            touch_y: 0.0
        };
    }

    // ------------------------------------------------------------
    // Render Commands
    // ------------------------------------------------------------

    fn panther_game_render_create(width, height) {
        return {
            width: width,
            height: height,
            commands: [],
            next_z: 0
        };
    }

    fn panther_game_render_width(state) { return state.width; }
    fn panther_game_render_height(state) { return state.height; }
    fn panther_game_render_commands(state) { return state.commands; }
    fn panther_game_render_count(state) { return len(state.commands); }

    fn panther_game_render_add(state, cmd) {
        return {
            width: state.width,
            height: state.height,
            commands: array_push(state.commands, cmd),
            next_z: state.next_z + 1
        };
    }

    fn panther_game_render_reset(state) {
        return {
            width: state.width,
            height: state.height,
            commands: [],
            next_z: 0
        };
    }

    fn panther_game_render_resize(state, w, h) {
        return {
            width: w,
            height: h,
            commands: state.commands,
            next_z: state.next_z
        };
    }

    fn panther_game_render_prepare_frame(state, r, g, b, a) {
        let clear_cmd = {type: "clear", r: r, g: g, b: b, a: a};
        return {
            width: state.width,
            height: state.height,
            commands: [clear_cmd],
            next_z: 1
        };
    }

    fn panther_game_render_serialize_commands(state) {
        return {
            width: state.width,
            height: state.height,
            count: len(state.commands),
            commands: state.commands
        };
    }

    // Primitive: filled rectangle
    fn panther_game_render_fill_rect(state, x, y, w, h, fill) {
        return panther_game_render_add(state, {
            type: "fill_rect",
            x: x, y: y, w: w, h: h,
            fill: fill
        });
    }

    // Primitive: stroked rectangle
    fn panther_game_render_stroke_rect(state, x, y, w, h, stroke, width) {
        return panther_game_render_add(state, {
            type: "stroke_rect",
            x: x, y: y, w: w, h: h,
            stroke: stroke,
            line_width: width
        });
    }

    // Primitive: filled rounded rectangle
    fn panther_game_render_fill_round_rect(state, x, y, w, h, r, fill) {
        return panther_game_render_add(state, {
            type: "fill_round_rect",
            x: x, y: y, w: w, h: h,
            radius: r,
            fill: fill
        });
    }

    // Primitive: filled circle
    fn panther_game_render_fill_circle(state, cx, cy, r, fill) {
        return panther_game_render_add(state, {
            type: "fill_circle",
            cx: cx, cy: cy, r: r,
            fill: fill
        });
    }

    // Primitive: stroked circle
    fn panther_game_render_stroke_circle(state, cx, cy, r, stroke, width) {
        return panther_game_render_add(state, {
            type: "stroke_circle",
            cx: cx, cy: cy, r: r,
            stroke: stroke,
            line_width: width
        });
    }

    // Primitive: line
    fn panther_game_render_line(state, x1, y1, x2, y2, stroke, width) {
        return panther_game_render_add(state, {
            type: "line",
            x1: x1, y1: y1, x2: x2, y2: y2,
            stroke: stroke,
            line_width: width
        });
    }

    // Primitive: text
    fn panther_game_render_text(state, text_str, x, y, fill, size) {
        return panther_game_render_add(state, {
            type: "text",
            text: text_str,
            x: x, y: y,
            fill: fill,
            font_size: size,
            font_family: "monospace"
        });
    }

    // Primitive: sprite (image placeholder for browser bridge)
    fn panther_game_render_sprite(state, sprite_id, x, y, w, h, opacity) {
        return panther_game_render_add(state, {
            type: "sprite",
            sprite_id: sprite_id,
            x: x, y: y, w: w, h: h,
            opacity: opacity,
            rotation: 0.0,
            flip_x: false,
            flip_y: false
        });
    }

    // Primitive: sprite with transforms
    fn panther_game_render_sprite_ex(state, sprite_id, x, y, w, h, rotation, opacity, flip_x, flip_y) {
        return panther_game_render_add(state, {
            type: "sprite",
            sprite_id: sprite_id,
            x: x, y: y, w: w, h: h,
            opacity: opacity,
            rotation: rotation,
            flip_x: flip_x,
            flip_y: flip_y
        });
    }

    // Helper: convert color object to CSS-style dict
    fn panther_game_render_color(r, g, b, a) {
        return {r: r, g: g, b: b, a: a};
    }

    // Helper: validate a render state has no null/undefined commands
    fn panther_game_render_validate(state) {
        let cmds = state.commands;
        for i in 0..len(cmds)-1 {
            let c = cmds[i];
            if c.type == "invalid" { return false; }
        }
        return true;
    }

    // ------------------------------------------------------------
    // Entity System
    // ------------------------------------------------------------

    fn panther_game_entity_create(eid, name, x, y) {
        return {
            id: eid, name: name,
            active: true, visible: true,
            x: x, y: y, rotation: 0.0,
            scale_x: 1.0, scale_y: 1.0,
            vx: 0.0, vy: 0.0,
            tags: [],
            data: {},
            w: 0.0, h: 0.0,
            collision_type: "none",
            hp: 1, max_hp: 1,
            speed: 0.0
        };
    }

    fn panther_game_entity_get_id(ent) { return ent.id; }
    fn panther_game_entity_get_name(ent) { return ent.name; }
    fn panther_game_entity_is_active(ent) { return ent.active; }
    fn panther_game_entity_is_visible(ent) { return ent.visible; }
    fn panther_game_entity_get_x(ent) { return ent.x; }
    fn panther_game_entity_get_y(ent) { return ent.y; }
    fn panther_game_entity_get_pos(ent) { return {x: ent.x, y: ent.y}; }
    fn panther_game_entity_get_vx(ent) { return ent.vx; }
    fn panther_game_entity_get_vy(ent) { return ent.vy; }
    fn panther_game_entity_get_hp(ent) { return ent.hp; }
    fn panther_game_entity_get_max_hp(ent) { return ent.max_hp; }

    fn panther_game_entity_set_pos(ent, x, y) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: x, y: y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_move(ent, dx, dy) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x + dx, y: ent.y + dy, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_set_velocity(ent, vx, vy) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: vx, vy: vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_set_active(ent, active) {
        return {id: ent.id, name: ent.name,
            active: active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_set_visible(ent, visible) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_set_size(ent, w, h) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: w, h: h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_add_tag(ent, tag) {
        let new_tags = array_push(ent.tags, tag);
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: new_tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_has_tag(ent, tag) {
        for i in 0..len(ent.tags)-1 {
            if ent.tags[i] == tag { return true; }
        }
        return false;
    }

    fn panther_game_entity_set_data(ent, key, value) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_is_alive(ent) { return ent.hp > 0; }
    fn panther_game_entity_take_damage(ent, dmg) {
        let new_hp = ent.hp - dmg;
        if new_hp < 0 { new_hp = 0; }
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: new_hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_entity_heal(ent, amount) {
        let new_hp = ent.hp + amount;
        if new_hp > ent.max_hp { new_hp = ent.max_hp; }
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: new_hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    // ------------------------------------------------------------
    // Scene System
    // ------------------------------------------------------------

    fn panther_game_scene_create(name) {
        return {
            name: name,
            entities: [],
            active: false,
            elapsed: 0.0
        };
    }

    fn panther_game_scene_get_name(scene) { return scene.name; }
    fn panther_game_scene_is_active(scene) { return scene.active; }
    fn panther_game_scene_entity_count(scene) { return len(scene.entities); }
    fn panther_game_scene_elapsed(scene) { return scene.elapsed; }

    fn panther_game_scene_enter(scene) {
        return {
            name: scene.name,
            entities: scene.entities,
            active: true,
            elapsed: 0.0
        };
    }

    fn panther_game_scene_exit(scene) {
        return {
            name: scene.name,
            entities: scene.entities,
            active: false,
            elapsed: scene.elapsed
        };
    }

    fn panther_game_scene_add_entity(scene, entity) {
        let new_entities = array_push(scene.entities, entity);
        return {
            name: scene.name,
            entities: new_entities,
            active: scene.active,
            elapsed: scene.elapsed
        };
    }

    fn panther_game_scene_remove_entity(scene, eid) {
        let new_entities = [];
        for i in 0..len(scene.entities)-1 {
            if scene.entities[i].id != eid {
                new_entities = array_push(new_entities, scene.entities[i]);
            }
        }
        return {
            name: scene.name,
            entities: new_entities,
            active: scene.active,
            elapsed: scene.elapsed
        };
    }

    fn panther_game_scene_find_entity(scene, eid) {
        for i in 0..len(scene.entities)-1 {
            if scene.entities[i].id == eid { return scene.entities[i]; }
        }
        return {id: "null", name: ""};
    }

    fn panther_game_scene_find_entities_by_tag(scene, tag) {
        let result = [];
        for i in 0..len(scene.entities)-1 {
            if panther_game_entity_has_tag(scene.entities[i], tag) {
                result = array_push(result, scene.entities[i]);
            }
        }
        return result;
    }

    fn panther_game_scene_update(scene, dt) {
        return {
            name: scene.name,
            entities: scene.entities,
            active: scene.active,
            elapsed: scene.elapsed + dt
        };
    }

    fn panther_game_scene_get_active_entities(scene) {
        let result = [];
        for i in 0..len(scene.entities)-1 {
            let ent = scene.entities[i];
            if ent.active {
                result = array_push(result, ent);
            }
        }
        return result;
    }

    fn panther_game_scene_clear(scene) {
        return {
            name: scene.name,
            entities: [],
            active: scene.active,
            elapsed: scene.elapsed
        };
    }

    // ------------------------------------------------------------
    // Collision Detection
    // ------------------------------------------------------------

    fn panther_game_collision_aabb(x1, y1, w1, h1, x2, y2, w2, h2) {
        return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
    }

    fn panther_game_collision_circle(cx1, cy1, r1, cx2, cy2, r2) {
        let dx = cx1 - cx2;
        let dy = cy1 - cy2;
        let dist_sq = dx * dx + dy * dy;
        let rad_sum = r1 + r2;
        return dist_sq < rad_sum * rad_sum;
    }

    fn panther_game_collision_point_rect(px, py, rx, ry, rw, rh) {
        return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
    }

    fn panther_game_collision_point_circle(px, py, cx, cy, r) {
        let dx = px - cx;
        let dy = py - cy;
        return dx * dx + dy * dy < r * r;
    }

    fn panther_game_collision_entities(e1, e2) {
        if !e1.active || !e2.active { return false; }
        let ct1 = e1.collision_type;
        let ct2 = e2.collision_type;
        if ct1 == "none" || ct2 == "none" { return false; }
        if ct1 == "rect" && ct2 == "rect" {
            return panther_game_collision_aabb(e1.x, e1.y, e1.w, e1.h,
                e2.x, e2.y, e2.w, e2.h);
        }
        if ct1 == "circle" && ct2 == "circle" {
            return panther_game_collision_circle(e1.x, e1.y, e1.w,
                e2.x, e2.y, e2.w);
        }
        if ct1 == "rect" && ct2 == "circle" {
            return panther_game_collision_point_rect(e2.x, e2.y,
                e1.x, e1.y, e1.w, e1.h);
        }
        if ct1 == "circle" && ct2 == "rect" {
            return panther_game_collision_point_rect(e1.x, e1.y,
                e2.x, e2.y, e2.w, e2.h);
        }
        return false;
    }

    fn panther_game_collision_check_world_bounds(entity, world_w, world_h) {
        let hit_left = entity.x < 0;
        let hit_right = entity.x + entity.w > world_w;
        let hit_top = entity.y < 0;
        let hit_bottom = entity.y + entity.h > world_h;
        return {
            left: hit_left, right: hit_right,
            top: hit_top, bottom: hit_bottom,
            any: hit_left || hit_right || hit_top || hit_bottom
        };
    }

    fn panther_game_collision_clamp_to_world(entity, world_w, world_h) {
        let ex = entity.x;
        let ey = entity.y;
        if ex < 0 { ex = 0; }
        if ex + entity.w > world_w { ex = world_w - entity.w; }
        if ey < 0 { ey = 0; }
        if ey + entity.h > world_h { ey = world_h - entity.h; }
        return {id: entity.id, name: entity.name,
            active: entity.active, visible: entity.visible,
            x: ex, y: ey, rotation: entity.rotation,
            scale_x: entity.scale_x, scale_y: entity.scale_y,
            vx: entity.vx, vy: entity.vy,
            tags: entity.tags, data: entity.data,
            w: entity.w, h: entity.h,
            collision_type: entity.collision_type,
            hp: entity.hp, max_hp: entity.max_hp, speed: entity.speed};
    }

    // ------------------------------------------------------------
    // Physics Foundation
    // ------------------------------------------------------------

    fn panther_game_physics_update(ent, dt, friction, gravity) {
        let new_vx = ent.vx * pow(1.0 - friction, dt);
        let new_vy = (ent.vy + gravity * dt) * pow(1.0 - friction, dt);
        let new_x = ent.x + new_vx * dt;
        let new_y = ent.y + new_vy * dt;
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: new_x, y: new_y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: new_vx, vy: new_vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_physics_apply_impulse(ent, ix, iy) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx + ix, vy: ent.vy + iy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_physics_bounce(ent, normal_x, normal_y, restitution) {
        let dot = ent.vx * normal_x + ent.vy * normal_y;
        let new_vx = ent.vx - (1.0 + restitution) * dot * normal_x;
        let new_vy = ent.vy - (1.0 + restitution) * dot * normal_y;
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: new_vx, vy: new_vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_physics_set_speed(ent, speed) {
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x, y: ent.y, rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: speed};
    }

    fn panther_game_physics_move_toward(ent, target_x, target_y, dt) {
        let dx = target_x - ent.x;
        let dy = target_y - ent.y;
        let dist = sqrt(dx * dx + dy * dy);
        if dist < 0.5 { return ent; }
        let move_amount = ent.speed * dt;
        if move_amount > dist { move_amount = dist; }
        let ratio = panther_game_math_div(move_amount, dist);
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x + dx * ratio, y: ent.y + dy * ratio,
            rotation: ent.rotation,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: ent.vx, vy: ent.vy,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    fn panther_game_physics_move_along(ent, angle_rad, dt) {
        let move_x = cos(angle_rad) * ent.speed * dt;
        let move_y = sin(angle_rad) * ent.speed * dt;
        return {id: ent.id, name: ent.name,
            active: ent.active, visible: ent.visible,
            x: ent.x + move_x, y: ent.y + move_y,
            rotation: angle_rad,
            scale_x: ent.scale_x, scale_y: ent.scale_y,
            vx: move_x, vy: move_y,
            tags: ent.tags, data: ent.data,
            w: ent.w, h: ent.h,
            collision_type: ent.collision_type,
            hp: ent.hp, max_hp: ent.max_hp, speed: ent.speed};
    }

    // ------------------------------------------------------------
    // Animation System (Phase 7)
    // ------------------------------------------------------------

    fn panther_game_anim_create(frame_ids, frame_durations, looping) {
        return {frames: frame_ids, durations: frame_durations,
            looping: looping, frame_index: 0, elapsed: 0.0,
            playing: false, done: false};
    }

    fn panther_game_anim_play(anim) {
        return {frames: anim.frames, durations: anim.durations,
            looping: anim.looping, frame_index: 0, elapsed: 0.0,
            playing: true, done: false};
    }

    fn panther_game_anim_stop(anim) {
        return {frames: anim.frames, durations: anim.durations,
            looping: anim.looping, frame_index: 0, elapsed: 0.0,
            playing: false, done: true};
    }

    fn panther_game_anim_pause(anim) {
        return {frames: anim.frames, durations: anim.durations,
            looping: anim.looping, frame_index: anim.frame_index,
            elapsed: anim.elapsed, playing: false, done: anim.done};
    }

    fn panther_game_anim_resume(anim) {
        return {frames: anim.frames, durations: anim.durations,
            looping: anim.looping, frame_index: anim.frame_index,
            elapsed: anim.elapsed, playing: true, done: anim.done};
    }

    fn panther_game_anim_update(anim, dt) {
        if !anim.playing || anim.done { return anim; }
        let new_elapsed = anim.elapsed + dt;
        let frame_idx = anim.frame_index;
        let num_frames = len(anim.frames);
        while new_elapsed >= anim.durations[frame_idx] {
            new_elapsed = new_elapsed - anim.durations[frame_idx];
            frame_idx = frame_idx + 1;
            if frame_idx >= num_frames {
                if anim.looping {
                    frame_idx = 0;
                } else {
                    return {frames: anim.frames, durations: anim.durations,
                        looping: anim.looping, frame_index: num_frames - 1,
                        elapsed: 0.0, playing: false, done: true};
                }
            }
        }
        return {frames: anim.frames, durations: anim.durations,
            looping: anim.looping, frame_index: frame_idx,
            elapsed: new_elapsed, playing: true, done: false};
    }

    fn panther_game_anim_get_frame(anim) {
        return anim.frames[anim.frame_index];
    }

    fn panther_game_anim_is_playing(anim) {
        return anim.playing;
    }

    fn panther_game_anim_is_done(anim) {
        return anim.done;
    }

    // ------------------------------------------------------------
    // Camera System (Phase 9)
    // ------------------------------------------------------------

    fn panther_game_camera_create(x, y, w, h) {
        return {x: x, y: y, w: w, h: h, zoom: 1.0, rotation: 0.0};
    }

    fn panther_game_camera_move(cam, dx, dy) {
        return {x: cam.x + dx, y: cam.y + dy, w: cam.w, h: cam.h,
            zoom: cam.zoom, rotation: cam.rotation};
    }

    fn panther_game_camera_set_pos(cam, x, y) {
        return {x: x, y: y, w: cam.w, h: cam.h,
            zoom: cam.zoom, rotation: cam.rotation};
    }

    fn panther_game_camera_follow(cam, target_x, target_y, lerp, dt) {
        let new_x = cam.x + (target_x - cam.w / 2 - cam.x) * lerp * dt;
        let new_y = cam.y + (target_y - cam.h / 2 - cam.y) * lerp * dt;
        return {x: new_x, y: new_y, w: cam.w, h: cam.h,
            zoom: cam.zoom, rotation: cam.rotation};
    }

    fn panther_game_camera_set_zoom(cam, zoom) {
        return {x: cam.x, y: cam.y, w: cam.w, h: cam.h,
            zoom: zoom, rotation: cam.rotation};
    }

    fn panther_game_camera_world_to_screen(cam, wx, wy) {
        return {x: (wx - cam.x) * cam.zoom, y: (wy - cam.y) * cam.zoom};
    }

    fn panther_game_camera_screen_to_world(cam, sx, sy) {
        return {x: sx / cam.zoom + cam.x, y: sy / cam.zoom + cam.y};
    }

    // ------------------------------------------------------------
    // UI Helpers (Phase 9)
    // ------------------------------------------------------------

    fn panther_game_ui_button(label, x, y, w, h) {
        return {type: "button", label: label, x: x, y: y, w: w, h: h,
            hovered: false, pressed: false};
    }

    fn panther_game_ui_text(text, x, y, size_r, color) {
        return {type: "text", text: text, x: x, y: y, size: size_r,
            color: color};
    }

    fn panther_game_ui_panel(x, y, w, h, bg_color) {
        return {type: "panel", x: x, y: y, w: w, h: h, color: bg_color};
    }

    fn panther_game_ui_is_hovered(ui_elem, mx, my) {
        return mx >= ui_elem.x && mx <= ui_elem.x + ui_elem.w
            && my >= ui_elem.y && my <= ui_elem.y + ui_elem.h;
    }

    fn panther_game_ui_set_hovered(ui_elem, hovered) {
        if ui_elem.type == "button" {
            return {type: "button", label: ui_elem.label,
                x: ui_elem.x, y: ui_elem.y, w: ui_elem.w, h: ui_elem.h,
                hovered: hovered, pressed: ui_elem.pressed};
        }
        return ui_elem;
    }

    fn panther_game_ui_set_pressed(ui_elem, pressed) {
        if ui_elem.type == "button" {
            return {type: "button", label: ui_elem.label,
                x: ui_elem.x, y: ui_elem.y, w: ui_elem.w, h: ui_elem.h,
                hovered: ui_elem.hovered, pressed: pressed};
        }
        return ui_elem;
    }

    // ------------------------------------------------------------
    // Storage / Save Data (Phase 10)
    // ------------------------------------------------------------

    fn panther_game_storage_create() {
        return {pairs: [], dirty: false};
    }

    fn panther_game_storage_set(storage, key, value) {
        let new_pairs = [];
        let n = len(storage.pairs);
        let found = false;
        let i = 0;
        while i < n {
            let pair = storage.pairs[i];
            if pair[0] == key {
                new_pairs = array_push(new_pairs, [key, value]);
                found = true;
            } else {
                new_pairs = array_push(new_pairs, pair);
            }
            i = i + 1;
        }
        if !found {
            new_pairs = array_push(new_pairs, [key, value]);
        }
        return {pairs: new_pairs, dirty: true};
    }

    fn panther_game_storage_get(storage, key, default_val) {
        let n = len(storage.pairs);
        let i = 0;
        while i < n {
            if storage.pairs[i][0] == key {
                return storage.pairs[i][1];
            }
            i = i + 1;
        }
        return default_val;
    }

    fn panther_game_storage_has(storage, key) {
        let n = len(storage.pairs);
        let i = 0;
        while i < n {
            if storage.pairs[i][0] == key { return true; }
            i = i + 1;
        }
        return false;
    }

    fn panther_game_storage_remove(storage, key) {
        let new_pairs = [];
        let n = len(storage.pairs);
        let i = 0;
        while i < n {
            if storage.pairs[i][0] != key {
                new_pairs = array_push(new_pairs, storage.pairs[i]);
            }
            i = i + 1;
        }
        return {pairs: new_pairs, dirty: true};
    }

    fn panther_game_storage_is_dirty(storage) {
        return storage.dirty;
    }

    fn panther_game_storage_clear_dirty(storage) {
        return {pairs: storage.pairs, dirty: false};
    }

    fn panther_game_storage_all_data(storage) {
        return storage.pairs;
    }

    // ------------------------------------------------------------
    // Debug / Profiling (Phase 11)
    // ------------------------------------------------------------

    fn panther_game_debug_create() {
        return {
            fps: 0.0, frame_time: 0.0, draw_calls: 0,
            entity_count: 0, collision_checks: 0,
            memory_mb: 0.0, active: false
        };
    }

    fn panther_game_debug_toggle(debug) {
        return {fps: debug.fps, frame_time: debug.frame_time,
            draw_calls: debug.draw_calls,
            entity_count: debug.entity_count,
            collision_checks: debug.collision_checks,
            memory_mb: debug.memory_mb, active: !debug.active};
    }

    fn panther_game_debug_update(debug, fps, dt, draw_calls, entity_count) {
        return {fps: fps, frame_time: dt, draw_calls: draw_calls,
            entity_count: entity_count,
            collision_checks: debug.collision_checks,
            memory_mb: debug.memory_mb, active: debug.active};
    }

    fn panther_game_debug_record_collision(debug) {
        return {fps: debug.fps, frame_time: debug.frame_time,
            draw_calls: debug.draw_calls,
            entity_count: debug.entity_count,
            collision_checks: debug.collision_checks + 1,
            memory_mb: debug.memory_mb, active: debug.active};
    }

    fn panther_game_debug_reset_collisions(debug) {
        return {fps: debug.fps, frame_time: debug.frame_time,
            draw_calls: debug.draw_calls,
            entity_count: debug.entity_count,
            collision_checks: 0,
            memory_mb: debug.memory_mb, active: debug.active};
    }

    fn panther_game_debug_report(debug) {
        return "FPS: " + to_string(debug.fps)
            + " | Frame: " + to_string(debug.frame_time * 1000) + "ms"
            + " | Draw: " + to_string(debug.draw_calls)
            + " | Entities: " + to_string(debug.entity_count)
            + " | Collisions: " + to_string(debug.collision_checks);
    }

    // ------------------------------------------------------------
    // Audio Commands (Phase 8, render-command style)
    // ------------------------------------------------------------

    fn panther_game_audio_cmd_play(id, src, volume, looping) {
        return {type: "audio_play", id: id, src: src,
            volume: volume, looping: looping};
    }

    fn panther_game_audio_cmd_stop(id) {
        return {type: "audio_stop", id: id};
    }

    fn panther_game_audio_cmd_volume(id, volume) {
        return {type: "audio_volume", id: id, volume: volume};
    }
}
