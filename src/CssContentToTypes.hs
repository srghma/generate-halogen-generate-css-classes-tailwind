module CssContentToTypes where

import "protolude" Protolude
import Text.Regex.Base
import Text.RE.PCRE.Text
import Text.CSS.Parse
import Data.String.QQ
import qualified Data.Text as Text
import qualified Data.List as List
import qualified Data.List.Extra as List
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Set.NonEmpty (NESet)
import qualified Data.Set.NonEmpty as NESet
import Data.Map (Map)
import qualified Data.Map as Map
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NonEmpty
import qualified CssContentToTypeNames as CssContentToTypeNames
import qualified "cases" Cases

newtype FunctionName = FunctionName { unFunctionName :: Text } deriving (Eq, Show, Ord)
newtype OriginalName = OriginalName { unOriginalName :: Text } deriving (Eq, Show, Ord)
newtype ScopeName    = ScopeName    { unScopeName :: Text } deriving (Eq, Show, Ord)

originalNameToFunctionName :: OriginalName -> FunctionName
originalNameToFunctionName (OriginalName originalName) = FunctionName $ classNameToFunctionName $ lastDef "" $ Text.splitOn "\\:" originalName
  where
    -- __ is a block, -- is now ____ and is a modifier
    classNameToFunctionName :: Text -> Text
    classNameToFunctionName = Text.replace "-" "_" . Text.replace "--" "____"

data TailwindClasses = TailwindClasses (Set OriginalName) (Map ScopeName TailwindClasses)
  deriving (Eq, Show, Ord)

cssContentToTypes :: Text -> TailwindClasses
cssContentToTypes cssContent = go $ fmap OriginalName $ Set.toList $ CssContentToTypeNames.cssContentToTypeNames cssContent
    where
      go :: [OriginalName] -> TailwindClasses
      go texts = foldr (\item accum -> addToTailwindClasses item accum) (TailwindClasses Set.empty Map.empty) texts

      createTailwindClass :: [ScopeName] -> OriginalName -> TailwindClasses
      createTailwindClass [] content = TailwindClasses (Set.singleton content) Map.empty
      createTailwindClass (scope:scopeTail) content = TailwindClasses Set.empty (Map.singleton scope (createTailwindClass scopeTail content))

      createOrUpdateTailwindClass :: [ScopeName] -> OriginalName -> TailwindClasses -> TailwindClasses
      createOrUpdateTailwindClass []                content (TailwindClasses set map) = TailwindClasses (Set.insert content set) map
      createOrUpdateTailwindClass (scope:scopeTail) content (TailwindClasses set map) =
        case Map.lookup scope map of
          Nothing -> TailwindClasses set (Map.insert scope (createTailwindClass scopeTail content) map)
          Just mapInside -> TailwindClasses set (Map.insert scope (createOrUpdateTailwindClass scopeTail content mapInside) map)

      addToTailwindClasses :: OriginalName -> TailwindClasses -> TailwindClasses
      addToTailwindClasses originalName oldTailwindClasses =
        case List.unsnoc $ fmap (ScopeName . Cases.process Cases.title Cases.camel) $ Text.splitOn "\\:" $ unOriginalName originalName of
            Nothing -> oldTailwindClasses
            Just (scopes, _) -> createOrUpdateTailwindClass scopes originalName oldTailwindClasses
