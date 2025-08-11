// This is the OpenSCAD source for a parameterized cable wire comb that is
// used to maintain the arrangement of wires within a cable harness or of
// cables within a bundle.
//
// The comb is made up of bars that when fitted together make rows of radiused
// holes to run wires through.  The bars fit together using pegs facing one
// way and holes to receive the pegs facing the other way.  Four different
// pieces can be rendered from this file.  "PegEnd" is flat on one side and
// has pegs on the other side.  Similarly, "HoleEnd" is flat on one side and
// has holes for pegs on the other side.  The "Center" piece has pegs on
// one side and holes for pegs on the other side.  Depending on how many rows
// you want in your comb, zero or more "Center" pieces may be fitted
// between a "HoleEnd" and a "PegEnd".  Another option is to render a solid
// two row wire comb using "2RowSolid".
//
// The number of holes in a row, the diameter of the holes, the thickness of
// the comb and other parameters can be modified using OpenSCAD's Customizer
// (or by editing this file).
//
// I print "PegEnd" and "HoleEnd" pieces with the flat side opposite the pegs
// or peg holes down.  I print "Center" pieces with the holes down and pegs
// up.  For all pieces I print a brim on the base plate to minimize warpage
// and to join the first layer of a "Center" piece all together.

// BSD Zero Clause License
//
// Copyright (c) 2025 Scott A. Anderson
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

// Select whether a PegEnd, Center, HoleEnd or 2RowSolid is rendered.
PIECE = "PegEnd"; // [PegEnd, Center, HoleEnd, 2RowSolid]

// Number of holes in a row of the comb.
N = 8;
// Diameter of the holes for the wires.
HOLE_D = 5;
// Thickness of the comb.
THICKNESS = 5.2;  // 0.4
// Difference in the diameter of the peg vs. the hole for the peg.
PEG_CLEARANCE = 0.3;  // 0.1
// Difference in the length of the peg vs. the depth of the hole for the peg.
PEG_END_CLEARANCE = 0.5;  // 0.1
// Pad amount to prevent Z-fighting & "may not be a valid 2-manifold" warnings.
PAD = 0.01;  // 0.01
// Minimum size of arc's fragment.
$fs = 0.1;  // 0.1

/* [Hidden] */
// The radius of the holes for the wires.
HOLE_R = HOLE_D / 2;
// The radiused holes for the wires are formed as tori.  The body of the torus
// has the same diameter as the thickness of the comb.
TORUS_D = THICKNESS;
TORUS_R = TORUS_D / 2;
// Center to center distance between the radiused wire holes.
HOLE_C_TO_C = HOLE_D + TORUS_D;
// Total depth of the wire comb form.
DEPTH = N * (HOLE_D + TORUS_D) + TORUS_D;
// PAD * 2 is used frequently.
PADX2 = PAD * 2;

// Create a torus centered on the origin with a center hole of radius
// <hole_radius> and the body of the torus having a radius of <torus_radius>.
module torus(torus_radius, hole_radius)
{
    rotate_extrude()
        translate([hole_radius + torus_radius, 0, 0])
            circle(r=torus_radius);
}

// Create a shape that is described by the central hole of a torus centered on
// the origin with whose radius is <hole_radius> and the body of the torus
// having a radius of <torus_radius>.
module torus_hole(torus_radius, hole_radius)
{
    cylinder_height = (torus_radius + PAD) * 2;
    cylinder_radius = torus_radius + hole_radius;
    difference() {
        cylinder(h=cylinder_height, r=cylinder_radius, center=true);
        torus(torus_radius, hole_radius);
    }
}

// Create an array of <n_x> by <n_y> tori holes with the first centered on the
// origin and the others extending out along the positive X and Y axes
// separated by <center_to_center>.
module torus_hole_array(torus_radius, hole_radius, center_to_center, n_x, n_y)
{
    for (x = [0 : center_to_center : center_to_center * (n_x - 1)])
        for (y = [0 : center_to_center : center_to_center * (n_y - 1)])
            translate([x, y, 0])
                torus_hole(torus_radius, hole_radius);
}

// Create a row of <n_y> cylinders with the first having its axis on the X
// axis and its base on the YZ plane and the others extending out along the Y
// axis separated by <center_to_center>.
module row_of_cylinders(cylinder_height, cylinder_diameter,
                        center_to_center, n_y)
{
    for (y = [0 : center_to_center : center_to_center * n_y])
        translate([0, y, 0])
            rotate([0, 90, 0])
                cylinder(h=cylinder_height, d=cylinder_diameter);
}

// Subsequent modules make use of globals instead of parameters.

// Create N cylinders positioned to be row <row_n> of either pegs or peg holes.
module row_of_pegs_or_holes(row_n, cylinder_height, cylinder_diameter)
{
    x_pos = (TORUS_D + HOLE_R) + ((row_n - 1) * HOLE_C_TO_C) - PAD;
    translate([x_pos, TORUS_R, TORUS_R])
        row_of_cylinders(cylinder_height=cylinder_height + PAD,
                         cylinder_diameter=cylinder_diameter,
                         center_to_center=HOLE_C_TO_C, n_y=N);
}

// Create the pegs for row <row_n>.
module row_of_pegs(row_n)
{
    row_of_pegs_or_holes(row_n,
                         cylinder_height=TORUS_R, cylinder_diameter=TORUS_R);
}

// Create the peg holes for row <row_n>.
module row_of_peg_holes(row_n)
{
    row_of_pegs_or_holes(row_n,
                         cylinder_height=TORUS_R + PEG_END_CLEARANCE,
                         cylinder_diameter=TORUS_R + PEG_CLEARANCE);
}

// Create the shape of an entire wire comb that has two holes along the X axis
// and <N> holes along the Y axis.  It will extend out from the origin in the
// positive X, Y and Z axes.
module comb_form()
{
    difference() {
        cube([2 * (HOLE_D + TORUS_D) + TORUS_D, DEPTH, THICKNESS]);
        translate([TORUS_D + HOLE_R, TORUS_D + HOLE_R, TORUS_R])
            torus_hole_array(TORUS_R + PAD, HOLE_R, HOLE_C_TO_C, 2, N);
    }
}

// Create a cube to intersect with comb_form() to create PIECE but without
// pegs and holes for pegs.
module piece_clip_box()
{
    if (PIECE == "PegEnd") {
        translate([-PAD, -PAD, -PAD])
            cube([TORUS_D + HOLE_R + PAD, DEPTH + PADX2, THICKNESS + PADX2]);
    } else if (PIECE == "Center") {
        translate([TORUS_D + HOLE_R, -PAD, -PAD])
            cube([TORUS_D + HOLE_D, DEPTH + PADX2, THICKNESS + PADX2]);
    } else if (PIECE == "HoleEnd") {
        translate([2 * TORUS_D + 3 * HOLE_R, -PAD, -PAD])
            cube([TORUS_D + HOLE_R + PAD, DEPTH + PADX2, THICKNESS + PADX2]);
    }
}

// Create PIECE but without pegs and holes for pegs.
module piece_without_pegs_nor_peg_holes()
{
    intersection() {
        comb_form();
        piece_clip_box();
    }
}

if (PIECE == "PegEnd") {
    piece_without_pegs_nor_peg_holes();
    row_of_pegs(1);
} else if (PIECE == "Center") {
    difference() {
        piece_without_pegs_nor_peg_holes();
        row_of_peg_holes(1);
    }
    row_of_pegs(2);
} else if (PIECE == "HoleEnd") {
    difference() {
        piece_without_pegs_nor_peg_holes();
        row_of_peg_holes(2);
    }
} else if (PIECE == "2RowSolid") {
    comb_form();
}
