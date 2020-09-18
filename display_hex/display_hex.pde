import java.util.Arrays;

int x_length = 1920;
int y_length = 1080;

int x_centre = x_length / 2;
int y_centre = y_length / 2;

int boundary = 6;

int s = floor((y_length/(2*boundary + 1))*0.6);

Table data;
int max_frame;

void setup() {
  size(1920, 1080);
  
  data = loadTable("hex_prob_t.csv");
  
  int[] times = {};
  for (int i = 0; i < data.getRowCount(); i++) {
    TableRow row = data.getRow(i);
    
    times = Arrays.copyOf(times, times.length + 1);
    times[times.length - 1] = Integer.parseInt(row.getString(0).split("\\.")[0]);
  }
  
  Arrays.sort(times);
  max_frame = times[times.length-1];
  
  frameRate(4);
  
}

void draw() {
  background(256);

  if (frameCount >= max_frame) {
    noLoop();
  }

  clear();
  textSize(50);
  text("t = " + Integer.toString(frameCount), 150, 150);
  drawPoints(data, s, frameCount);
  
  //saveFrame("output/fc_####");
}

void drawHexagon(float x, float y, float colour, float radius) {
  float angle = TWO_PI / 6;
  fill(colour);
  
  beginShape();
    for (float a = PI / 2; a < TWO_PI + PI / 2; a += angle) {
      float sx = x + cos(a) * radius;
      float sy = y + sin(a) * radius;
      vertex(sx, sy);
    }
    endShape(CLOSE);
}

float[] toPixel(float x, float y, float z, int size) {
  float y1 = y_centre + (1.5 * size * z);
  float x1 = x_centre + (sqrt(3)*size * ( (z/2) + x));
  
  float[] ret = {x1, y1};
  
  return ret;
}

void drawPoints(Table d, int size, int t) {
  Iterable<TableRow> rows = d.findRows(Integer.toString(t)+".0", 0);
  
  
  Table d2 = new Table();
  d2.addColumn("t");
  d2.addColumn("x");
  d2.addColumn("y");
  d2.addColumn("z");
  d2.addColumn("p");

  for (TableRow tr : rows) {
    TableRow newRow = d2.addRow();
    newRow.setString(0, tr.getString(0));
    newRow.setString(1, tr.getString(1));
    newRow.setString(2, tr.getString(2));
    newRow.setString(3, tr.getString(3));
    newRow.setString(4, tr.getString(4));
  }

  float[] frequencies = {};
  for (int i = 0; i < d2.getRowCount(); i++) {
    TableRow row = d2.getRow(i);
    
    frequencies = Arrays.copyOf(frequencies, frequencies.length + 1);
    frequencies[frequencies.length - 1] = Float.parseFloat(row.getString(4));
  }

  Arrays.sort(frequencies);

  float ma = frequencies[frequencies.length - 1];
  float a = 256 / ma;

  for (int i = 0; i < d2.getRowCount(); i++) {
    TableRow row = d2.getRow(i);
    
    float x = Float.parseFloat(row.getString(1));
    float y = Float.parseFloat(row.getString(2));
    float z = Float.parseFloat(row.getString(3));
    float p = Float.parseFloat(row.getString(4));
    
    float[] pixel = toPixel(x, y, z, size);
    push();
    drawHexagon(pixel[0], pixel[1], (a*p), size);
    pop();
  }
}
