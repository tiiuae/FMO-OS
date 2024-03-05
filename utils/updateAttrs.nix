# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
rec {
  unique = builtins.foldl' (acc: e:
                if builtins.elem e acc then acc else acc ++ [ e ]) [];

  concatOrOverwriteList = (
    # Bool flag to choose to overwrite rhs list wih lhs or concatenate both lists
    # true - overwrite
    # false - concatenate
    pred:
    # Left attribute set of the merge.
    lhs:
    # Right attribute set of the merge.
    rhs:
    if pred
    then
      lhs
    else
      unique (builtins.concatLists [lhs rhs]));

  updateAttrs =
    # Bool flag to choose to overwrite rhs list wih lhs or concatenate both lists
    # true - overwrite
    # false - concatenate
    overwriteList:
    # Left attribute set of the merge.
    lhs:
    # Right attribute set of the merge.
    rhs:
    let f = (attrPath: builtins.zipAttrsWith (n: values:
      let here = attrPath ++ [n]; in
      if builtins.length values == 1
      then
        builtins.head values
      else
        if (builtins.isList (builtins.elemAt values 1) && builtins.isList (builtins.head values))
        then
          if builtins.isAttrs (builtins.head (builtins.concatLists [(builtins.head values) (builtins.elemAt values 1)]))
          then
            [ (f [] (builtins.concatLists [(builtins.head values) (builtins.elemAt values 1)])) ]
          else
            concatOrOverwriteList overwriteList (builtins.head values) (builtins.elemAt values 1)
        else
          if (builtins.isAttrs (builtins.elemAt values 1) && builtins.isAttrs (builtins.head values))
          then
            f here values
          else
            builtins.head values
      ));
    in
      f [] [rhs lhs];
}
