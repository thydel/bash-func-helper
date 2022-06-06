def scalar:
  def s: { boolean, number, string } | keys;
  type | IN(s[]);

def scalar:
  def s: ({ boolean, number, string } | keys);
  def s: [ "null", "boolean", "number", "string" ];
  type | IN(s[]);

def scalar: type as $i | { null, boolean, number, string } | has($i);

def scalar: type | IN("null", "boolean", "number", "string");

def m(d; v; e):
  if d | scalar then d | v else empty end;

[1, "a", null, true, [], {}] | map(scalar)

				
