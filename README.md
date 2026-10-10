# Parametric sim-rig cable management box

Parametric OpenSCAD model. Two printed parts: a body and a snap-on lid.

## Files

| File | What it is |
|---|---|
| `sim_rig_cable_box.scad` | the model, all dimensions parametric |
| `stl/sim_rig_cable_box_box.stl` | body, 40 × 160 × 47.6 default |
| `stl/sim_rig_cable_box_lid.stl` | lid, already oriented for printing (plate down) |

## Design

- **Cable openings are open at the bottom edge** of the walls (mouse-hole style),
  so cables enter at floor level and the rim stays closed all the way round.
  One 30 mm opening in each end wall (24 mm high) and one 20 mm opening in each
  side wall (18 mm high). The arch tops have a 45° roof so they print without
  supports.
- **Lid**: inner lip in four flexing segments with a double-ramped snap detent per
  segment, plus four corner tabs that locate it lengthwise. Push on, pull off, no
  screws.
- **Floor**: four zip-tie bridges (6 mm wide slots) to strap bundles down, and two
  M6 through-holes (6.4 mm clearance) on 140 mm centres for T-nuts in 4040 extrusion.
- **Lid vents**: 15 slots, for power bricks that run warm.
- Usable interior: 45.2 × 155.2 × 45.2 mm.

## Printing

Both parts print flat with **no supports**.

- Body: open side up, as exported.
- Lid: as exported — plate on the bed, lip pointing up.
- 0.2 mm layers, 3 perimeters, 20 % infill. PETG or ABS/ASA if the rig sits in a
  warm room or near a PSU; PLA is fine otherwise.
- The snap lip is 1.9 mm thick and must flex ~0.45 mm. Don't print it at 0.3 mm
  layers with 4 perimeters — it gets stiff and brittle.

## Fit adjustment

If the lid is too tight or too loose, change one line at the top of the `.scad`:

```
clr    = 0.25;   // raise to 0.35 if the lid won't seat, lower to 0.15 if it rattles
snap_p = 0.7;    // detent height — lower for an easier open, raise for a firmer click
```

## Other parameters worth knowing

```
total_w / total_l / total_h   outer envelope, lid included
wall / floor_t / lid_t        2.4 mm throughout
end_slot_w, end_slot_depth    end openings (depth = height up from the bottom)
side_slot_w, side_slot_depth  side openings
lip_h, snap_drop              lip depth and where the detent sits on it
vents, anchors, mount_holes   true/false
mount_spacing                 distance between the two M6 holes
```

## Re-exporting after a change

```
openscad -o box.stl -D 'part="box"' sim_rig_cable_box.scad
openscad -o lid.stl -D 'part="lid"' sim_rig_cable_box.scad
```

`part` also accepts `"both"` (both parts laid out side by side for one print job)
and `"assembled"` (preview only).
