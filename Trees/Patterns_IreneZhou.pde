class Lattice extends LXPattern {
  final SawLFO spin = new SawLFO(0, 12 * 360, 12 * 800); 
  final SinLFO yClimb = new SinLFO(60, 30, 9600);

  float coil(float basis) {
    return sin(basis*PI);
  }

  Lattice(LX lx) {
    super(lx);
    addModulator(spin.start());
    addModulator(yClimb.start());
  }

  public void run(double deltaMs) {
    float spinf = spin.getValuef();
    float coilf = 2*coil(spin.getBasisf());
    for (Cube cube : model.cubes) {
      float wrapdistleft = LXUtils.wrapdistf(cube.theta, spinf + (model.yMax - cube.y) * coilf, 180);
      float wrapdistright = LXUtils.wrapdistf(cube.theta, -spinf - (model.yMax - cube.y) * coilf, 180);
      float width = yClimb.getValuef() + (cube.y/model.yMax) * 50;
      float df = min(100, 3 * max(0, wrapdistleft - width) + 3 * max(0, wrapdistright - width));

      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + .2*cube.y - 360) % 360, 
        100, 
        df
      );
    }
  }
}


class Pulley extends LXPattern { //ported from SugarCubes
  final int NUM_DIVISIONS = 2;
  private final Accelerator[] gravity = new Accelerator[NUM_DIVISIONS];
  private final Click[] delays = new Click[NUM_DIVISIONS];

  private final Click reset = new Click(9000);
  private boolean isRising = false;
  float coil = 10;

  private BasicParameter sz = new BasicParameter("SIZE", 0.5);
  private BasicParameter beatAmount = new BasicParameter("BEAT", 0);

  Pulley(LX lx) {
    super(lx);
    for (int i = 0; i < NUM_DIVISIONS; ++i) {
      addModulator(gravity[i] = new Accelerator(0, 0, 0));
      addModulator(delays[i] = new Click(0));
    }
    addModulator(reset).start();
    addParameter(sz);
    addParameter(beatAmount);
    trigger();
  }
  
  private void trigger() {
    isRising = !isRising;
    int i = 0;
    for (Accelerator g : gravity) {
      if (isRising) {
        g.setSpeed(random(20, 33), 0).start();
      } 
      else {
        g.setVelocity(0).setAcceleration(-420);
        delays[i].setDuration(random(0, 500)).trigger();
      }
      ++i;
    }
  }

  public void run(double deltaMS) {
    if (reset.click()) {
      trigger();
    } 
    if (!isRising) {
      int j = 0;
      for (Click d : delays) {
        if (d.click()) {
          gravity[j].start();
          d.stop();
        }
        ++j;
      }
      for (Accelerator g : gravity) {
        if (g.getValuef() < 0) {
          g.setValue(-g.getValuef());
          g.setVelocity(-g.getVelocityf() * random(0.74, 0.84));
        }
      }
    }

    float fPos = 1 -lx.tempo.rampf();
    if (fPos < .2) {
      fPos = .2 + 4 * (.2 - fPos);
    }

    float falloff = 100. / (3 + sz.getValuef() * 36 + fPos * beatAmount.getValuef()*48);
    for (Cube cube : model.cubes) {
      int gi = (int) constrain((cube.x - model.xMin) * NUM_DIVISIONS / (model.xMax - model.xMin), 0, NUM_DIVISIONS-1);
      float yn =  cube.y/model.yMax;
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + abs(cube.x - model.cx)*.8 + cube.y*.4) % 360, 
        constrain(100 *(0.8 -  yn * yn), 0, 100), 
        max(0, 100 - abs(cube.y/2 - 50 - gravity[gi].getValuef())*falloff)
      );
    }
  }
}

class Springs extends LXPattern {
  private final Accelerator gravity = new Accelerator(0, 0, 0);
  private final Click reset = new Click(9600);
  private boolean isRising = false;
  final SinLFO spin = new SinLFO(0, 360, 9600);
  
  float coil(float basis) {
    return 4 * sin(basis*TWO_PI + PI) ;
  }

  Springs(LX lx) {
    super(lx);
    addModulator(gravity);
    addModulator(reset).start();
    addModulator(spin.start());
    trigger();
  }

  private void trigger() {
    isRising = !isRising;
    if (isRising) {
      gravity.setSpeed(0.25, 0).start();
    } 
    else {
      gravity.setVelocity(0).setAcceleration(-1.75);
    }
  }

  public void run(double deltaMS) {
    if (reset.click()) {
      trigger();
    }
    
    if (!isRising) {
      gravity.start();
      if (gravity.getValuef() < 0) {
        gravity.setValue(-gravity.getValuef());
        gravity.setVelocity(-gravity.getVelocityf() * random(0.74, 0.84));
      }
    }

    float spinf = spin.getValuef();
    float coilf = 2*coil(spin.getBasisf());
    
    for (Cube cube : model.cubes) {
      float yn =  cube.y/model.yMax;
      float width = (1-yn) * 25;
      float wrapdist = LXUtils.wrapdistf(cube.theta, spinf + (cube.y) * 1/(gravity.getValuef() + 0.2), 360);
      float df = max(0, 100 - max(0, wrapdist-width));
      colors[cube.index] = lx.hsb(
        max(0, lx.getBaseHuef() - yn * 20), 
        constrain((1- yn) * 100 + wrapdist, 0, 100),
        max(0, df - yn * 50)
      );
    }
  }
}

