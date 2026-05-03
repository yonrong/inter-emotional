// ─────────────────────────────────────────────────────────────────────────────
// Synapse.pde
// ─────────────────────────────────────────────────────────────────────────────

class Synapse {

  NeuronNode a, b;
  PVector    cp1, cp2;

  float strength   = 0;
  float fireTimer  = 0;
  float fireRate   = 3.0;
  float curveTimer = 0;

  ArrayList<SignalParticle> particles = new ArrayList<SignalParticle>();

  Synapse(NeuronNode _a, NeuronNode _b) {
    a = _a; b = _b;
    curveTimer = random(6, 14);
    rebuildCurve();
  }

  void rebuildCurve() {
    PVector mid  = PVector.lerp(a.pos, b.pos, 0.5);
    PVector diff = PVector.sub(b.pos, a.pos);
    PVector perp = new PVector(-diff.y, diff.x).normalize().mult(random(-75, 75));
    cp1 = PVector.add(PVector.lerp(a.pos, mid, 0.33), perp);
    cp2 = PVector.add(PVector.lerp(mid, b.pos, 0.67), perp);
  }

  void update() {
    float d = PVector.dist(a.pos, b.pos);
    strength = constrain(map(d, 40, MAX_SYN_DIST, 1.0, 0.0), 0, 1);

    float avgAct = (a.activation + b.activation) * 0.5;
    fireRate = map(avgAct, 0, 1, 4.2, 0.55);

    fireTimer -= 1.0 / 60.0;
    if (fireTimer <= 0 && strength > 0.07) {
      fireTimer = fireRate + random(-0.15, 0.15);
      spawnSignal();
    }

    curveTimer -= 1.0 / 60.0;
    if (curveTimer <= 0) {
      curveTimer = random(8, 16);
      rebuildCurve();
    }

    for (int i = particles.size() - 1; i >= 0; i--) {
      SignalParticle p = particles.get(i);
      p.update();
      if (p.shouldNotify()) {
        NeuronNode target = p.aToB ? b : a;
        target.receivePulse(p.c, strength * 0.62);
      }
      if (p.dead()) particles.remove(i);
    }
  }

  void spawnSignal() {
    boolean dir    = (random(1) > 0.5);
    NeuronNode src = dir ? a : b;
    if (src.activation > 0.04)
      particles.add(new SignalParticle(this, dir));
  }

  PVector bezierAt(float t) {
    return new PVector(
      bezierPoint(a.pos.x, cp1.x, cp2.x, b.pos.x, t),
      bezierPoint(a.pos.y, cp1.y, cp2.y, b.pos.y, t)
    );
  }

  void render() {
    if (strength < 0.015) return;

    float nodeAlpha = (a.alpha / 100.0) * (b.alpha / 100.0);
    float alphaBase = strength * nodeAlpha;
    float avgAct    = (a.activation + b.activation) * 0.5;
    float swCore    = strength * map(avgAct, 0, 1, 0.5, 2.2);
    float swGlow    = swCore * 4.5;

    final int STEPS = 24;
    noFill();

    // ── 通道一：外光暈（寬、白調、低透明度）────────────────
    for (int i = 0; i < STEPS; i++) {
      float t1 = (float)i       / STEPS;
      float t2 = (float)(i + 1) / STEPS;
      PVector p1 = bezierAt(t1);
      PVector p2 = bezierAt(t2);
      color c = lerpColorHSB(a.eColor, b.eColor, (t1 + t2) * 0.5);
      strokeWeight(swGlow);
      stroke(hue(c), saturation(c) * 0.18, 100, alphaBase * 18);
      line(p1.x, p1.y, p2.x, p2.y);
    }

    // ── 通道二：中層彩色線（情感色漸變）────────────────────
    for (int i = 0; i < STEPS; i++) {
      float t1 = (float)i       / STEPS;
      float t2 = (float)(i + 1) / STEPS;
      PVector p1 = bezierAt(t1);
      PVector p2 = bezierAt(t2);
      color c = lerpColorHSB(a.eColor, b.eColor, (t1 + t2) * 0.5);
      strokeWeight(swCore);
      stroke(hue(c), saturation(c), brightness(c), alphaBase * 30);
      line(p1.x, p1.y, p2.x, p2.y);
    }

    for (SignalParticle p : particles) p.render();
  }
}
