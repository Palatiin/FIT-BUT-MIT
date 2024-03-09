-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

module Src.Type
  (
    DTree(..)
  ) where

-- DT: feature index, threshold
--   Left Node, Right Node
data DTree index threshold
  = String
  | Node Int index Float threshold
    (DTree index threshold)
    (DTree index threshold)
  deriving (Show)
