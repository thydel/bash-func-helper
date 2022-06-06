#!/usr/bin/env -S jq -nf

def scalar:
  def scalar: null | { null, boolean, number, string } | keys[];
  type | IN(scalar);

def m(d; v; e):
  if d | scalar then d | v else empty end;

[1, "a", null, true, [], {}] | map(scalar)

				
