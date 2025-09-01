/**
 * Naz Sevinç
 * Creative Coding course
 * Instructor: Alba G. Corral
 * Generative art piece exploring roots, migration, and belonging.
 */

// ——————————————————————————
//  GLOBALS & IMAGES
// ——————————————————————————
PImage figureImg, armsImg;
ArrayList<Root> roots;
color[] palette;
PVector startPoint;

// ROOT CONFIG
int numRoots       = 20;
int maxDepth       = 6;
int growthInterval = 15;   // frames between growth steps
int maxActiveRoots = 3;    // no more than 3 growing at once

// NOISE & TIMING
float noiseScale = 0.005;
float timeScale  = 0.01;

// Tracks how many roots are “in progress”
int activeCount = 0;

void setup() {
  size(800, 800);
  smooth();
  
  // Load background & arms (put them in sketch’s /data folder)
  figureImg = loadImage("figure.png");
  armsImg   = loadImage("arms.png");
  
  // Define palette using provided hex codes
  palette = new color[]{
    unhex("FF9DCBAF"), // #9DCBAF
    unhex("FFF2AB97"), // #F2AB97
    unhex("FF82C4F0"), // #82C4F0
    unhex("FFEDC77C"), // #EDC77C
    unhex("FFF4BAB0")  // #F4BAB0
  };
  
  // All roots start here (centered, 150px up from bottom)
  startPoint = new PVector(width/2, height - 150);
  
  // Create initial roots
  initRoots();
}

void draw() {
  background(0);
  
  // Draw background silhouette
  imageMode(CENTER);
  image(figureImg, width/2, height/2, 800, 800);
  
  // Every growthInterval frames, try to start & update roots
  if (frameCount % growthInterval == 0) {
    for (Root r : roots) {
      r.tryStart();
      r.update();
    }
  }
  
  // Draw all roots (with continuous noise‐driven jitter)
  for (Root r : roots) {
    r.display();
  }
  
  // Overlay arms on front
  imageMode(CORNER);
  image(armsImg, 0, 0, width, height);
}

// Restart everything on mouse click
void mousePressed() {
  initRoots();
}

// Initialize roots list
void initRoots() {
  roots = new ArrayList<Root>();
  activeCount = 0;
  for (int i = 0; i < numRoots; i++) {
    float angle = random(-PI * 0.8, -PI * 0.2);
    color c     = palette[int(random(palette.length))];
    int delayF  = int(random(0, 300));  // random start delay
    roots.add(new Root(startPoint.copy(), angle, c, 8, 0, delayF));
  }
}

// ——————————————————————————
//  ROOT CLASS
// ——————————————————————————
class Root {
  ArrayList<Branch> branches;
  int delay;
  boolean started = false;
  boolean active  = false;
  
  Root(PVector pos, float angle, color col, float thick, int depth, int delayFrames) {
    delay      = delayFrames;
    branches   = new ArrayList<Branch>();
    branches.add(new Branch(pos, angle, col, thick, depth));
  }
  
  // Attempt to start growth if delay passed & slots available
  void tryStart() {
    if (!started && frameCount > delay && activeCount < maxActiveRoots) {
      started    = true;
      active     = true;
      activeCount++;
    }
  }
  
  // Only grow if started
  void update() {
    if (!started) return;
    
    ArrayList<Branch> newKids = new ArrayList<Branch>();
    for (Branch b : branches) {
      newKids.addAll(b.grow());
    }
    branches.addAll(newKids);
    
    // Check completion: no branch can still spawn
    if (active && isComplete()) {
      activeCount--;
      active = false;
    }
  }
  
  // A root is “complete” when every branch has already grown
  boolean isComplete() {
    for (Branch b : branches) {
      if (!b.grown && b.depth < maxDepth) {
        return false;
      }
    }
    return true;
  }
  
  void display() {
    if (!started && !active) return;
    for (Branch b : branches) {
      b.show();
    }
  }
}

// ——————————————————————————
//  BRANCH CLASS
// ——————————————————————————
class Branch {
  PVector pos, dir;
  float   len, thickness;
  int     depth;
  color   col;
  boolean grown = false;
  
  Branch(PVector pos, float angle, color col, float thickness, int depth) {
    this.pos       = pos;
    this.dir       = PVector.fromAngle(angle);
    this.len       = random(30, 80);
    this.thickness = thickness;
    this.depth     = depth;
    this.col       = col;
  }
  
  // Spawn children once
  ArrayList<Branch> grow() {
    ArrayList<Branch> kids = new ArrayList<Branch>();
    if (!grown && thickness > 1 && depth < maxDepth) {
      int splits = int(random(1, 3));
      for (int i = 0; i < splits; i++) {
        float newAng = dir.heading() + random(-PI/5, PI/5);
        PVector tip  = PVector.add(pos, PVector.mult(dir, len));
        kids.add(new Branch(tip, newAng, col, thickness * 0.7, depth + 1));
      }
    }
    grown = true;
    return kids;
  }
  
  // Draw curved segment with noise‐animated jitter & depth fade
  void show() {
    PVector end = PVector.add(pos, PVector.mult(dir, len));
    
    // Perlin noise → jitter angle
    float n  = noise(pos.x * noiseScale, pos.y * noiseScale, frameCount * timeScale);
    float ja = map(n, 0, 1, -PI/4, PI/4);
    
    // Control points
    PVector cp1 = PVector.add(pos,
                    new PVector(cos(dir.heading()+ja), sin(dir.heading()+ja))
                      .mult(len * 0.4));
    PVector cp2 = PVector.add(pos,
                    new PVector(cos(dir.heading()-ja), sin(dir.heading()-ja))
                      .mult(len * 0.7));
    
    // Fade by depth
    float alpha = map(depth, 0, maxDepth, 255, 50);
    
    stroke(red(col), green(col), blue(col), alpha);
    strokeWeight(thickness);
    noFill();
    bezier(pos.x, pos.y,
           cp1.x, cp1.y,
           cp2.x, cp2.y,
           end.x, end.y);
  }
}
