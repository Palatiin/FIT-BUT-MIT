-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 12.03.2024

module Src.CART
  (
   buildTree
  ) where

import Data.List (sort, groupBy)
import Data.Either (lefts)

import Src.Type (DTree(..))


sortOn :: (Ord b, Ord a) => (a -> b) -> [a] -> [a]
sortOn f xs = map snd . sort $ [(f x, x) | x <- xs]

-- get all values from i-th column in the dataset
getColumnValues :: Int -> [[Either Float String]] -> [Float]
getColumnValues index dataset = lefts $ map (!! index) dataset

-- calculate thresholds from features - average of two consecutive values
getThresholds :: [Float] -> [Float]
getThresholds [] = []
getThresholds [_] = []
getThresholds (x : xs) = (x + head xs) / 2 : getThresholds xs

-- split dataset on the given feature and threshold
splitByThreshold :: (Ord a) => Int -> a -> [[Either a b]] -> ([[Either a b]], [[Either a b]])
splitByThreshold index threshold dataset = (left, right)
  where
    left = filter (\x -> removeLeft (x !! index) < threshold) dataset
    right = filter (\x -> removeLeft (x !! index) >= threshold) dataset

-- calculate Gini impurity of the given dataset
calculateGini :: [[Either Float String]] -> Float
calculateGini dataset =
  let
    total = fromIntegral $ length dataset
    gini = 1 - sum [
      (fromIntegral (length group) / total) * (fromIntegral (length group) / total)
      | group <- groupBy (==) $ sort $ map last dataset
      ]
  in gini

-- split dataset on the given feature and threshold, and calculate Gini impurity of the subsets
giniIndex :: Int -> Float -> [[Either Float String]] -> Float
giniIndex index threshold dataset =
  let
    (left, right) = splitByThreshold index threshold dataset
    total = fromIntegral $ length dataset
    leftTotal = fromIntegral $ length left
    rightTotal = fromIntegral $ length right
    leftGini = calculateGini left
    rightGini = calculateGini right
  in (leftTotal / total) * leftGini + (rightTotal / total) * rightGini

-- find best split using Gini impurity
findBestSplit :: [[Either Float String]] -> (Int, Float, Float)
findBestSplit dataset =
  let
    -- all possible splits, and their giniIndexes
    splits = [
      (index, threshold, giniIndex index threshold dataset)
      | index <- [0..(length $ init $ dataset !! 0) - 1]
      , threshold <- getThresholds $ sort $ getColumnValues index dataset
      ]
  -- return item with lowest giniIndex - best split
  in (sortOn (\(_, _, gini) -> gini) splits) !! 0

-- check if all elements in the list are the same
allSameClass :: Eq a => [a] -> Bool
allSameClass [] = True
allSameClass xs = all (== head xs) (tail xs)

-- get value of the Left constructor
removeLeft :: Either a b -> a
removeLeft (Left x) = x
removeLeft _ = error "removeLeft"

-- get value of the Right constructor
removeRight :: Either a b -> b
removeRight (Right x) = x
removeRight _ = error "removeRight"

-- build decision tree using CART algorithm
buildTree :: [[Either Float String]] -> DTree
buildTree [] = EmptyDTree
buildTree dataset
  | allSameClass $ fmap last dataset = Leaf $ removeRight $ last $ head dataset
  | otherwise = Node index threshold (buildTree left) (buildTree right)
  where
    (index, threshold, _) = findBestSplit dataset
    (left, right) = splitByThreshold index threshold dataset
