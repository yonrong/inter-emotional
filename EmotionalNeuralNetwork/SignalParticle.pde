// ─────────────────────────────────────────────────────────────────────────────
// SignalParticle.pde
// ─────────────────────────────────────────────────────────────────────────────

class SignalParticle {

  Synapse synapse;
  boolean aToB;
  color   c;
  color   cDest;
  float   t;
  float   speed;
  float   alpha = 95;

  boolean _arrived  = false;
  boolean _notified = false;

  ArrayList<PVector> trail = new ArrayList<PVector>();
  final int TRAIL_LEN = 14;

  SignalParticle(Synapse _syn, boolean _aToB) {
    synapse = _syn;
    aToB    = _aToB;
    c       = _aToB ? _syn.a.eColor : _syn.b.eColor;
    cDest   = _aToB ? _syn.b.eColor : _syn.a.eColor;
    t       = _aToB ? 0.0 : 1.0;
    speed   = random(0.005, 0.013);
  }

  void update() {
    if (!_arrived) {
      t = aToB ? t + speed : t - speed;
      boolean done = aToB ? (t >= 1.0) : (t <= 0.0);
      if (done) { t = constrain(t, 0, 1); _arrived = true; }
    } else {
      alpha -= 6;
    }

    trail.add(0, synapse.bezierAt(t).copy());
    if (trail.size() > TRAIL_LEN) trail.remove(trail.size() - 1);
  }

  void render() {
    if (trail.isEmpty()) return;

    float progress = aToB ? t : (1.0 - t);
    color hdCol    = lerpColorHSB(c, cDest, progress);

    // ── 拖尾：漸小漸淡的小紅心串 ────────────────────────────────────────
    for (int i = 1; i < trail.size(); i++) {
      float ratio = (float)i / TRAIL_LEN;
      float a2    = alpha * (1.0 - ratio) * 0.52;
      float sz    = map(i, 1, trail.size() - 1, 10.0, 3.5);
      drawHeart(trail.get(i).x, trail.get(i).y, sz,
                0, 88, 100, a2);
    }

    // ── 頭部：情感色外光暈 + 主紅心 + 粉紅高光 ──────────────────────────
    PVector head = trail.get(0);

    // 情感色外光暈（保留情感系統的視覺線索）
    noStroke();
    fill(hue(hdCol), saturation(hdCol) * 0.4, 100, alpha * 0.28);
    ellipse(head.x, head.y, 28, 28);

    // 主紅心
    drawHeart(head.x, head.y, 18,
              0, 90, 100, alpha * 0.92);

    // 粉紅高光（略微上移製造立體感）
    drawHeart(head.x, head.y - 1.5, 9,
              345, 45, 100, alpha * 0.52);
  }

  // ── 心形繪製：三段 bezier ────────────────────────────────────────────────
  //    以 (cx, cy) 為重心，sz 為標稱尺寸
  void drawHeart(float cx, float cy, float sz,
                 float h, float s, float b, float a) {
    noStroke();
    fill(h, s, b, a);
    pushMatrix();
    translate(cx, cy);
    float r = sz / 2.0;
    beginShape();
    vertex(0,       r * 0.9);                                          // 底部尖端
    bezierVertex(-r*1.2,  r*0.3, -r*1.4, -r*0.6, -r*0.5, -r*0.9);   // 左半圓弧
    bezierVertex(-r*0.05, -r*0.5, r*0.05, -r*0.5,  r*0.5, -r*0.9);   // 頂部凹槽
    bezierVertex( r*1.4, -r*0.6,  r*1.2,  r*0.3,  0,       r*0.9);   // 右半圓弧
    endShape(CLOSE);
    popMatrix();
  }

  boolean shouldNotify() {
    if (_arrived && !_notified) { _notified = true; return true; }
    return false;
  }

  boolean dead() { return _arrived && alpha <= 0; }
}
