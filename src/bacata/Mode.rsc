// This module was taken from Salix. The original module name  can be found in: salix::lib::Mode
@license{
  Copyright (c) Tijs van der Storm <Centrum Wiskunde & Informatica>.
  All rights reserved.
  This file is licensed under the BSD 2-Clause License, which accompanies this project
  and is available under https://opensource.org/licenses/BSD-2-Clause.
}
@contributor{Tijs van der Storm - storm@cwi.nl - CWI}

module bacata::Mode

import IO;
import Set;
import Type;
import String;
import ParseTree;

data Mode
  = mode(str name, list[State] states, map[str, value] meta = ());
  
data State
  = state(str name, list[Rule] rules)
  ;
  
data Rule
  = rule(str regex, list[str] tokens, str next = "", bool indent=false, bool dedent=false)
  ;
  
str cat2token("StringLiteral") = "string";
str cat2token("Comment") = "comment";
str cat2token("Constant") = "atom";
str cat2token("Variable") = "variable";
str cat2token(str _) = "unknown";


Mode grammar2mode(str name, type[&T <: Tree] sym) {
  defs = sym.definitions;
  
  //rules = {p | /p:prod(_,_,_) := sym.definitions};
  //prefixrules = { <x,p> | p:prod(_,[lit(x),*_],_) <- rules};
  
  
  str reEsc(str c) //= c in {"*", "\\", "+", "?", "|"} ? "\\<c>" : c;
    = escape(c, ("*": "\\*", "\\": "\\\\", "+": "\\+", "?": "\\?", "|": "\\|", "^": "\\^", "/": "\\/", "^^": "\\^\\^"));
  
  set[str] lits = { x | /lit(x:/^[a-zA-Z0-9_@]*$/) := defs };
  list[str] litsOrdered = sort(lits, bool(str a, str b){return size(a) > size(b);});
  
  println(size(litsOrdered));
  // Tijs version
  //set[str] ops 
  //  = { x | /prod(_, [_, _, lit(x:/^[+\-\<\>=\<=!@#%^&*~\/|]*$/), _, _], ts) := defs, !any(\tag("category"("Comment")) <-  ts)}
  //  + { x | /prod(_, [lit(x:/^[+\-\<\>=\<=!@#%^&*~\/|]*$/), _, _], ts) := defs, !any(\tag("category"("Comment")) <-  ts) }
  //  + { x | /prod(_, [_, _, lit(x:/^[+\-\<\>=\<=!@#%^&*~\/|]*$/)], ts) := defs, !any(\tag("category"("Comment")) <-  ts) };
  set[str] ops
    = {x | /prod(_,symbols, ts) := defs, !isEmpty(symbols), a <- symbols, lit(x:/^[+\-\<\>\<=\>=!@#%^&*~\/|]*$/) := a, !any(\tag("category"("Comment")) <-  ts)};
    
    // Support ONLY for single line comments
    set[str] comments
    = { p | /prod(_, [lit(p), /conditional(_, {\end-of-line()})], y) := defs, \tag("category"("Comment")) <- y};
    //= {p | /prod(_,[lit(p),_,_],y) := defs, \tag("category"("Comment")) <-y}
    //+ {p | /prod(_,[lit(p),_],y) := defs, \tag("category"("Comment")) <- y};
    
  kwRule = rule("(?:<intercalate("|", [ l | l <- litsOrdered ])>)\\b", ["keyword"]);   
  opRule = rule("(?:<intercalate("|", [ reEsc(l) | l <- ops ])>)", ["operator"]);
  commRule = rule("<intercalate("|",  [ reEsc(l) + ".*" | l <- comments ])>", ["comment"]);
  // todo: add Variable with word boundaries.
     
  return mode(name, [state("start", [kwRule, opRule, commRule])], meta = ());
}