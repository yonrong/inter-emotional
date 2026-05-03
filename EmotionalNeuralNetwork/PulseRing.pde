// ─────────────────────────────────────────────────────────────────────────────
// PulseRing.pde
// 神經元放電時向外擴散的環形波，模擬突觸去極化（depolarization）視覺
// ─────────────────────────────────────────────────────────────────────────────

class PulseRing {

  PVector pos;    // 世界座標（建立時複製自 NeuronNode.pos）
  color   c;      // 攜帶的情感色彩
  float   r;      // 當前半徑
  float   maxR;   // 最大半徑（與激活強度正相關）
  float   alpha;  // 不透明度 0–100

  PulseRing(PVector _pos, color _c, float activation) {
    pos   = _pos.copy();
    c     = _c;
    r     = 5;
    maxR  = map(activation, 0, 1, 38, 115);
    alpha = 72;
  }

  void update() {
    r    += (maxR - r) * 0.09;   // 加速擴張後逐漸趨緩
    alpha -= 1.4;
  }

  // parentAlpha：來自所屬 NeuronNode 的淡入/淡出係數（0–100）
  void render(float parentAlpha) {
    if (alpha <= 0) return;
    noFill();
    strokeWeight(1.0);
    stroke(hue(c), saturation(c), brightness(c), alpha * parentAlpha / 100.0);
    ellipse(pos.x, pos.y, r * 2, r * 2);
  }

  boolean dead() { return alpha <= 0; }
}
