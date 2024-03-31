-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

module Src.Type
  (
    DTree(..)
  , readTree
  , classify
  ) where

import Data.Char (isSpace)
import Src.StringOps (strip, startsWith, splitBy)


-- Decision Tree data type
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
        helper (level + 1) left ++  -- format left subtree
        helper (level + 1) right    -- format right subtree

-- parse tree from the input
readTree :: [String] -> (DTree, [String])
readTree [] = (EmptyDTree, [])
readTree (line : rest)
  | sline `startsWith` "Node:" = (Node index threshold left right, restTree)
  | sline `startsWith` "Leaf:" = (Leaf cls, rest)
  | otherwise = error line
  where
    sline = strip line
    node_properties = splitBy ',' ( dropWhile isSpace $ drop (length "Node: ") sline )
    index = read $ node_properties !! 0
    threshold = read (strip $ node_properties !! 1)
    (left, restLeft) = if null rest then (EmptyDTree, []) else readTree rest
    (right, restTree) = if null restLeft then (EmptyDTree, []) else readTree restLeft
    cls = strip $ drop (length "Leaf: ") sline

-- classify input features using the decision tree
classify :: DTree -> [Float] -> String
classify _ [] = ""              -- empty input
classify EmptyDTree (_:_) = ""  -- empty tree
classify (Leaf cls) _ = cls
classify (Node index threshold left right) features
  | (features !! index) < threshold = classify left features
  | (features !! index) >= threshold = classify right features
  | otherwise = error "Classify error!"
