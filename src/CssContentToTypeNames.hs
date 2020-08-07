module CssContentToTypeNames (cssContentToTypeNames) where

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

-- [".myButton",".myButton",".myButton2","#myButton3","#myButton4",".myButton5",".classInsideClass",".classInsideClass2",,".classWithBefore2Pre",".classWithBefore2:before",".classWithBefore3:before",".classWithBefore3Post",".classInOneLine","#idInOneLine",".myButton3"]
--
-- from ".classWithBefore1:before" to "classWithBefore1"

type CssBlock = (Text, [(Text, Text)])

collectCssBlocks :: NestedBlock -> [CssBlock]
collectCssBlocks (NestedBlock mediaQuery nestedBlocks) = join $ fmap collectCssBlocks nestedBlocks
collectCssBlocks (LeafBlock cssBlock) = [cssBlock]

extractName :: CssBlock -> Text
extractName = fst

-- e.g. ".myButton3 > a"
extractClassesAndIds :: Text -> [Text]
extractClassesAndIds = List.filter (\t -> Text.isPrefixOf "." t) . Text.words

extractClassOrId :: Text -> Maybe Text
extractClassOrId css =
  join
  $ fmap (flip atMay 1)
  $ flip atMay 0
  -- $ traceShowId
  $ (css =~ [re|\.((\\\:|\w|\-)+)|] :: [[Text]])

cssContentToTypeNames :: Text -> Set Text
cssContentToTypeNames cssContent =
  Set.fromList
  $ catMaybes
  $ fmap extractClassOrId
  $ join
  $ fmap extractClassesAndIds
  $ fmap extractName
  $ join
  $ fmap collectCssBlocks
  $ either (const []) identity
  $ parseNestedBlocks cssContent
