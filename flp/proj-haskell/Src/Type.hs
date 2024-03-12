-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

module Src.Type
  (
    DTree(..)
  , readTree
  ) where

import Data.Char (isSpace)
import Src.StringOps (strip, startsWith, split)


-- DT: feature index, threshold
--   Left Node, Right Node
data DTree
  = EmptyDTree
  | Node Int Float DTree DTree
  | Leaf String

instance Show DTree where
  show tree = helper 0 tree
    where
      helper _ EmptyDTree = ""
      helper level (Leaf className) = replicate (2 * level) ' ' ++ "Leaf: " ++ className ++ "\n"
      helper level (Node index threshold left right) =
        replicate (2 * level) ' ' ++ "Node: " ++ show index ++ ", " ++ show threshold ++ "\n" ++
        helper (level + 1) left ++
        helper (level + 1) right

readTree :: [String] -> (DTree, [String])
readTree [] = (EmptyDTree, [])
readTree (line : rest)
  | sline `startsWith` "Node:" = (Node index threshold left right, restTree)
  | sline `startsWith` "Leaf:" = (Leaf cls, rest)
  | otherwise = error line
  where
    sline = strip line
    node_properties = split ( dropWhile isSpace $ drop (length "Node: ") sline ) ','
    index = read $ node_properties !! 0
    threshold = read (strip $ node_properties !! 1)
    (left, restLeft) = if null rest then (EmptyDTree, []) else readTree rest
    (right, restTree) = if null restLeft then (EmptyDTree, []) else readTree restLeft
    cls = strip $ drop (length "Leaf: ") sline
