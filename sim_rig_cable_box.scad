// =====================================================================
//  Sim-rig cable management box
//  Outer envelope: 50 (X, width) x 160 (Y, length) x 50 (Z, height)
//  incl. the lid. Snap-on lid, cable openings open at the bottom edge of
//  the walls so cables enter at floor level.
//
//  Export:
//    openscad -o box.stl -D part=\"box\" sim_rig_cable_box.scad
//    openscad -o lid.stl -D part=\"lid\" sim_rig_cable_box.scad
// =====================================================================

part = "both";      // "box" | "lid" | "both" (print layout) | "assembled"

// ---------- envelope ----------
total_w   = 50;     // X
total_l   = 160;    // Y
total_h   = 40;     // Z, lid included
wall      = 2.4;    // side walls
floor_t   = 2.4;    // bottom
lid_t     = 2.4;    // lid plate
corner_r  = 3.0;    // outer vertical corner radius
clr       = 0.25;   // fit clearance - raise to 0.35 if your printer runs tight

// ---------- cable openings (all open at the bottom edge) ----------
end_slot_w      = 30;   // in the two 50 mm end walls
end_slot_depth  = 24;   // opening height, measured up from the bottom
side_slot_w     = 20;   // in the two 160 mm side walls
side_slot_depth = 18;

// ---------- lid lip + snap detent ----------
lip_t     = 1.9;    // lip wall - thin enough to flex
lip_h     = 16;     // how far the lip reaches into the box
snap_p    = 0.7;    // detent height on the inner box wall
snap_h    = 3.0;    // detent length along Z
snap_drop = 13.0;   // detent centre below the rim - keep near the lip tip,
                    // that is what keeps the flex strain low
root_ch   = 1.0;    // 45-degree chamfer on the inside, where the lip meets the
                    // lid plate - takes the stress peak off a sharp corner
tab_h     = 5;      // corner locating tabs on the lid

// ---------- extras ----------
vents         = true;   // ventilation slots in the lid
anchors       = true;   // zip-tie bridges on the floor
mount_holes   = true;   // M6 through-holes for extrusion T-nuts
mount_spacing = 140;
mount_d       = 6.4;    // M6 clearance

$fn = 72;

// ---------------------------------------------------------------------
box_h   = total_h - lid_t;          // body height; lid plate sits on the rim
in_w    = total_w - 2*wall;         // cavity
in_l    = total_l - 2*wall;
in_r    = max(1.2, corner_r - wall + 0.8);
wall_x  = in_w/2;                   // inner face of the long walls
lip_out = wall_x - clr;             // outer face of the lid lip
snap_z  = box_h - snap_drop;        // bottom of the detent

// the lip runs in four segments: split at the middle of each long side and
// clear of the corner tabs, so each one can flex on its own
seg_a   = 11.75;                    // half the gap between the two segments
seg_b   = in_l/2 - 20;
seg_c   = (seg_a + seg_b)/2;        // segment centre
seg_l   = seg_b - seg_a;            // segment length
snap_y   = seg_c;                   // detents sit mid-segment
snap_len = seg_l - 8;

// =====================  helpers  =====================================
module rbox(w, l, h, r) {                       // rounded-corner prism
    hull() for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*(w/2 - r), sy*(l/2 - r), 0]) cylinder(r = r, h = h);
}

// arch-shaped cutter, open to the bottom, prism running along Y.
// The arch gets a 45-degree roof with a short flat cap so the body still
// prints without supports.
module uslot(w, depth, len) {
    r = w/2;
    c = depth - r - 1;                          // arch centre
    rotate([90, 0, 0]) linear_extrude(height = len, center = true)
        intersection() {
            hull() {
                translate([0, c]) circle(r = r);
                translate([0, c]) polygon([[-r/sqrt(2), r/sqrt(2)],
                                           [ r/sqrt(2), r/sqrt(2)],
                                           [0, r*sqrt(2)]]);
                translate([-r, -1]) square([w, 1]);
            }
            translate([-w, -1]) square([2*w, depth + 1]);
        }
}

// double-ramped detent, points toward +X, sits on z = 0
module detent(p, h, len) {
    rotate([90, 0, 0]) linear_extrude(height = len, center = true)
        polygon([[0, 0], [p, h/2], [0, h]]);
}

module zip_anchor() {                           // 6 mm wide zip-tie bridge
    difference() {
        translate([-5, -2.5, 0]) cube([10, 5, 5.2]);
        translate([-3, -3.5, 1.8]) cube([6, 7, 2.8]);
    }
}

// =====================  box body  ====================================
module box_body() {
    difference() {
        rbox(total_w, total_l, box_h, corner_r);

        // cavity
        translate([0, 0, floor_t]) rbox(in_w, in_l, box_h, in_r);

        // cable openings, end walls (cut through the wall only, floor stays)
        for (sy = [-1, 1])
            translate([0, sy*total_l/2, 0])
                uslot(end_slot_w, end_slot_depth, 2*wall + 0.02);

        // cable openings, side walls
        for (sx = [-1, 1])
            translate([sx*total_w/2, 0, 0])
                rotate([0, 0, 90]) uslot(side_slot_w, side_slot_depth, 2*wall + 0.02);

        // M6 mounting holes through the floor
        if (mount_holes)
            for (sy = [-1, 1]) translate([0, sy*mount_spacing/2, -1]) {
                cylinder(d = mount_d, h = floor_t + 2);
                translate([0, 0, floor_t + 0.6])
                    cylinder(d1 = mount_d, d2 = mount_d + 1.4, h = 0.7);
            }
    }

    // snap detents on the inner face of the two long walls
    // (added after the cavity cut, otherwise they get hollowed out again)
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*(wall_x + 0.01), sy*snap_y, snap_z])
            scale([-sx, 1, 1]) detent(snap_p + 0.01, snap_h, snap_len);

    if (anchors)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*12, sy*40, floor_t - 0.01]) zip_anchor();
}

// =====================  lid  =========================================
// 2D cross-section of one lip strip: chamfered lead-in at the bottom,
// chamfered root on the inner face at the top
module lip_profile(sx) {
    zb = box_h - lip_h;
    xo = lip_out;
    xi = lip_out - lip_t;
    c  = root_ch;
    polygon([[sx*xi, zb + 0.6], [sx*(xo - 1.0), zb], [sx*xo, zb + 1.0],
             [sx*xo, box_h + 1], [sx*(xi - c), box_h + 1],
             [sx*(xi - c), box_h], [sx*xi, box_h - c]]);
}

module lid() {
    difference() {
        union() {
            // plate, flush with the box footprint
            translate([0, 0, box_h]) rbox(total_w, total_l, lid_t, corner_r);

            // lip strips: two per long side, split in the middle
            for (sx = [-1, 1], sy = [-1, 1])
                translate([0, sy*seg_c, 0])
                    rotate([90, 0, 0]) linear_extrude(height = seg_l, center = true)
                        lip_profile(sx);

            // L-shaped corner tabs locate the lid along Y
            translate([0, 0, box_h - tab_h])
                intersection() {
                    difference() {
                        rbox(in_w - 2*clr, in_l - 2*clr, tab_h + 1, in_r);
                        translate([0, 0, -1])
                            rbox(in_w - 2*clr - 2*lip_t, in_l - 2*clr - 2*lip_t,
                                 tab_h + 3, max(0.8, in_r - lip_t));
                    }
                    union() for (sx = [-1, 1], sy = [-1, 1])
                        translate([sx*(in_w/2 - 6), sy*(in_l/2 - 6), 0])
                            cube([12, 12, tab_h*4], center = true);
                }
        }

        // detent pockets in the lip strips
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*(lip_out + 0.01), sy*snap_y, snap_z - 0.4])
                scale([-sx, 1, 1]) detent(snap_p + 0.35, snap_h + 0.8, snap_len + 2);

        // ventilation
        if (vents)
            for (x = [-13, 0, 13], y = [-44, -22, 0, 22, 44])
                translate([x, y, box_h - 1]) hull() {
                    translate([0, -7, 0]) cylinder(d = 3, h = lid_t + 2);
                    translate([0,  7, 0]) cylinder(d = 3, h = lid_t + 2);
                }
    }
}

// =====================  output  ======================================
if (part == "box") box_body();

// lid is printed upside down: plate on the bed, lip pointing up
if (part == "lid") translate([0, 0, total_h]) rotate([180, 0, 0]) lid();

if (part == "both") {
    box_body();
    translate([total_w + 12, 0, total_h]) rotate([180, 0, 0]) lid();
}

if (part == "assembled") { box_body(); lid(); }
