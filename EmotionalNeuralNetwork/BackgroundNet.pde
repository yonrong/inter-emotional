// ─────────────────────────────────────────────────────────────────────────────
// BackgroundNet.pde
// ─────────────────────────────────────────────────────────────────────────────

class BackgroundNet {

  ArrayList<BGNode> nodes = new ArrayList<BGNode>();
  ArrayList<BGEdge> edges = new ArrayList<BGEdge>();

  BackgroundNet(int count) {
    for (int i = 0; i < count; i++)
      nodes.add(new BGNode(random(width), random(height)));

    for (int i = 0; i < nodes.size(); i++)
      for (int j = i + 1; j < nodes.size(); j++) {
        float d = dist(nodes.get(i).x, nodes.get(i).y,
                       nodes.get(j).x, nodes.get(j).y);
        if (d < 210 && random(1) > 0.52)
          edges.add(new BGEdge(nodes.get(i), nodes.get(j)));
      }
  }

  void update() {
    for (BGNode bn : nodes) {
      bn.suppressed = false;
      for (NeuronNode nn : neurons) {
        if (nn.alpha > 15 && dist(bn.x, bn.y, nn.pos.x, nn.pos.y) < 230) {
          bn.suppressed = true;
          break;
        }
      }
      bn.update();
    }
    for (BGEdge e : edges) e.update();

    // 自發脈衝 + 連鎖傳播
    if (frameCount % 85 == 0 && random(1) > 0.38) {
      BGNode src = nodes.get((int)random(nodes.size()));
      src.pulse();
      for (BGEdge e : edges) {
        if ((e.a == src || e.b == src) && random(1) > 0.45) {
          BGNode nb = (e.a == src) ? e.b : e.a;
          if (!nb.suppressed) nb.glowDelayed(random(0.25, 1.0));
        }
      }
    }
  }

  void render() {
    for (BGEdge e : edges) e.render();
    for (BGNode bn : nodes) bn.render();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class BGNode {
  float   x, y;
  float   sz;          // 大小倍率（隨機，增加層次感）
  float   glow      = 0;
  float   glowDelay = 0;
  boolean suppressed = false;

  // 脈衝環
  float   ringR = 0;
  float   ringA = 0;

  BGNode(float _x, float _y) {
    x  = _x;
    y  = _y;
    sz = random(0.55, 2.0);
  }

  void pulse() {
    if (suppressed) return;
    glow  = 62;
    ringR = sz * 3;
    ringA = 45;
  }

  void glowDelayed(float delay) { glowDelay = delay; }

  void update() {
    if (glowDelay > 0) {
      glowDelay -= 1.0 / 60.0;
      if (glowDelay <= 0) pulse();
    }
    float decay = suppressed ? 4.5 : 0.7;
    glow = max(0, glow - decay / 60.0 * 60);

    // 脈衝環擴散淡出
    if (ringA > 0) {
      ringR += 1.5;
      ringA  = max(0, ringA - 1.2);
    }
  }

  void render() {
    noStroke();
    if (glow > 1) {
      // 外暈
      fill(0, 0, 55, glow * 0.18 * sz);
      ellipse(x, y, 18 * sz, 18 * sz);
      // 核心
      fill(0, 0, 82, glow * 0.88);
      ellipse(x, y, 4.5 * sz, 4.5 * sz);
    } else {
      fill(0, 0, 20, 14);
      ellipse(x, y, 3 * sz, 3 * sz);
    }

    // 脈衝環
    if (ringA > 1) {
      noFill();
      strokeWeight(0.6);
      stroke(0, 0, 50, ringA);
      ellipse(x, y, ringR * 2, ringR * 2);
      noStroke();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class BGEdge {
  BGNode a, b;
  float  alpha = 0;

  BGEdge(BGNode _a, BGNode _b) { a = _a; b = _b; }

  void update() {
    float target = (a.suppressed || b.suppressed) ? 0 : (a.glow + b.glow) * 0.10;
    alpha = lerp(alpha, target, 0.055);
  }

  void render() {
    stroke(0, 0, 32, 6 + alpha);
    strokeWeight(0.5);
    line(a.x, a.y, b.x, b.y);
  }
}
