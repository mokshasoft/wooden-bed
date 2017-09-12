/* Configuration */

pw  = 200;  // plank width
pt  = 30;   // plank thickness
bl  = 2000; // bed length
le  = 100;  // bed length extension
bw  = 1400; // bed width
we  = 100;  // bed width extension
mpw = 100;  // mattress support plank width
mpt = 20;   // mattress support plank thickness
bt  = 40;   // batten thickness
da  = 10;   // distance between batten and air hole
pd  = 10;   // wood plug diameter
ph  = 35;   // wood plug height

/* Helpers */

gr    = 1.61803; // golden ration
tl    = bl + 2*pt + 2*le; // total length
tw    = bw + 2*pt + 2*we; // total width
nbrSp = ceil((bl - mpw)/2/mpw); // number of support planks
eo    = bl - mpw*(nbrSp*2 - 1); // first mattress support plank offset
wpo   = [for (x = [0:nbrSp - 1]) x*mpw*2 - ((bl - eo - mpw)/2)]; // wood plug offsets

function acc(arr) = [for (x = [0:len(arr) - 2]) accP(arr, x)];
function accP(arr, x) = x == 0 ? arr[0] : arr[x] + accP(arr, x - 1);

module rightSide() {
    translate([0, bw/2 + pt/2, 0])
        sidePlank();
}
module topSide() {
    translate([bl/2 + pt/2, 0, 0])
        rotate([0, 0, 90])
        headPlank();
}

/* Assemble */

show_assembly = false; // set to true to show how the bed is assembled
show_offset_top = show_assembly ? -1.1*pw : 0;
show_offset_side = show_assembly ? 2*pt : 0;
show_offset_batten = show_assembly ? 2*mpt : 0;

translate([0, show_offset_side, 0])
    rightSide();
translate([0, -show_offset_side, 0])
    mirror([0, 1, 0]) rightSide();
batten();
mirror([0, 1, 0]) batten();
translate([0, 0, show_offset_top])
    topSide();
translate([0, 0, show_offset_top])
    mirror([1, 0, 0]) topSide();
translate([0, 0, show_offset_batten])
    mattressSupport();

/* mattress support */

module mattressSupport() {
    for (x = wpo)
        translate([x, 0, mpt/2 + da + bt])
        linear_extrude(height = mpt, center = true)
        difference() {
            off_y = (bw - pt)/2;
            square([mpw, bw], center = true);
            translate([0, off_y, 0]) hole();
            translate([0, -off_y, 0]) hole();
        };

    module hole() {
        circle(d = pd + 2, center = true);
    }
}

/* Bed support */

module batten() {
    translate([0, bw/2 - pt/2, bt/2 + da])
        union() {
            color("BurlyWood") cube([bl, pt, bt], center = true);
            off_x = mpw/2 - pd;
            off_z = bt/2 - ph/2;
            for (x = wpo) {
                translate([x, 0, off_z]) woodPlug();
                translate([x + off_x, 0, off_z]) rotate([-90, 0, 0]) woodPlug();
                translate([x - off_x, 0, off_z]) rotate([-90, 0, 0]) woodPlug();
            }
        }
}

module woodPlug() {
    color("Sienna") cylinder(d = pd, h = ph, center = false);
}

/* Long side bed plank */

module sidePlank() {
    cx = le/gr;
    cy = pw/gr;
    step =
        [ [0, 0]
        , [bl/2, 0]
        , [0, pw/2]
        , [pt, 0]
        , [0, -pw/2]
        , [le, 0]
        , [0, pw - cy]
        , [-cx, cy]
        , [-(tl/2 - cx), 0]
        , [0, -pw]
        ];
    difference() {
        generatePlank(bl, step);
        off_z = bt/2 + da;
        off_x = mpw/2 - pd;
        off_y = bt/2 - ph/2;
        for (x = wpo) {
                translate([x + off_x, off_y, off_z]) rotate([90, 0, 0]) hole();
                translate([x - off_x, off_y, off_z]) rotate([90, 0, 0]) hole();
        }
    }

    module hole() {
        cylinder(d = pd, h = ph, center = false);
    }
}

/* Short side bed plank */

module headPlank() {
    cx = we/gr;
    cy = pw/gr;
    step =
        [ [0, 0]
        , [tw/2, 0]
        , [0, pw - cy]
        , [-cx, cy]
        , [-(we - cx), 0]
        , [0, -pw/2]
        , [-pt, 0]
        , [0, pw/2]
        , [-bw/2, 0]
        , [0, -pw]
        ];
    generatePlank(bw, step);
}

/* Create a plank with an air hole */

module generatePlank(length, step) {
    rotate([90, 0, 0])
        translate([0, -pw/2, 0])
        linear_extrude(height = pt, center = true)
        difference() {
            union() {
                polygon(points = acc(step));
                mirror([1, 0]) polygon(points = acc(step));
            }
            // air hole
            translate([0, pw/2 - pw/4/gr])
                square([length/gr, pw/2/gr], center = true);
        };
}
