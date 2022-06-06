#!/usr/bin/env -S jq -nf

def is_scalar:
  def scalar: null | { null, boolean, number, string } | keys[];
type | IN(scalar);

def is_array(p): p | type == "array";
def is_array: is_array(.);

def is_var(p): (p | type) == "object" and (p | has("_"));

def add_var(p; e): e + { (p._): . };
def add_var(p; e): e + { d: ., p: p, var: { (p._): . }, status: true };

def add_status(p; e; b): e + { d: ., p: p, status: b };

def m_scalar(p; e):
  if is_var(p) then add_var(p; e)
  elif . == p then add_status(p; e; true)
  else add_status(p; e; false) end;


def m_object(p; e): empty;

def m(p; e):
  def add_array_var(p; e): e + { d: ., p: p, var: { (p._): map(m(p; e)) }};

  def m_array(p; e):
    if is_var(p) then add_array_var(p; e)
    elif is_array(p) then [., p] | transpose | map(. as [$d, $p] | $d | m($p; e))
    else add_status(p; e; false) end;		

  if is_scalar then m_scalar(p; e)
  elif is_array then m_array(p; e)
  else m_object(p; e)
  end;

				
