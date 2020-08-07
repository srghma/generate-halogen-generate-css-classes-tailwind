{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE PackageImports #-}

module Main where

-- TODO: use http://hackage.haskell.org/package/managed instead of turtle

-- TODO
-- dont use system-filepath (Filesystem.Path module, good lib, turtle is using it,         FilePath is just record)
-- dont use filepath        (System.FilePath module, bad lib,  directory-tree is using it, FilePath is just String)
-- use https://hackage.haskell.org/package/path-io-1.6.0/docs/Path-IO.html walkDirAccumRel

-- TODO
-- use https://hackage.haskell.org/package/recursion-schemes

-- import qualified Filesystem.Path.CurrentOS
import Options.Applicative
import "protolude" Protolude hiding (find, rootModuleName)
import qualified "turtle" Turtle
import "turtle" Turtle ((</>))
import qualified "directory" System.Directory
import qualified "filepath" System.FilePath
import qualified "system-filepath" Filesystem.Path
import "base" Data.String (String)
import qualified "base" Data.String as String
import qualified "base" Data.List as List
import qualified Data.List.Index as List
import qualified "text" Data.Text as Text
import qualified "cases" Cases
import Control.Concurrent.Async
import CssContentToTypes
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Set.NonEmpty (NESet)
import qualified Data.Set.NonEmpty as NESet
import Data.Map (Map)
import qualified Data.Map as Map
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NonEmpty

data AppOptions = AppOptions
  { input :: Turtle.FilePath
  , output :: Turtle.FilePath
  , rootModuleName :: Text
  }

appOptionsParser :: Parser AppOptions
appOptionsParser = AppOptions
  <$> strOption ( long "input" <> metavar "FILEPATH")
  <*> (strOption ( long "output" <> metavar "DIRECTORY") <&> makeValidDirectory)
  <*> strOption ( long "root-module-name" <> metavar "FILEPATH")

appOptionsParserInfo :: ParserInfo AppOptions
appOptionsParserInfo = info (appOptionsParser <**> helper)
  ( fullDesc
  <> progDesc "Generate css"
  <> header "Generate css" )

appendIfNotAlreadySuffix :: Eq a => [a] -> [a] -> [a]
appendIfNotAlreadySuffix suffix target =
  if List.isSuffixOf suffix target
     then target
     else target ++ suffix

stripSuffix :: Eq a => [a] -> [a] -> [a]
stripSuffix suffix target =
  if List.isSuffixOf suffix target
     then List.reverse $ List.drop (List.length suffix) $ List.reverse target
     else target

-- make it end with /
makeValidDirectory :: Turtle.FilePath -> Turtle.FilePath
makeValidDirectory = Turtle.decodeString . appendIfNotAlreadySuffix "/" . Turtle.encodeString

renderFileContent :: Text -> NonEmpty OriginalName -> Text
renderFileContent moduleName originalNames =
  let
    originalNameFunctionName :: [(OriginalName, FunctionName)] = map (\x -> (x, originalNameToFunctionName x)) (NonEmpty.toList originalNames)

    exports = originalNameFunctionName & map snd & map unFunctionName & Text.intercalate ", "

    functions = originalNameFunctionName
      & map (\(originalName :: OriginalName, functionName :: FunctionName) -> Text.unlines
                [ unFunctionName functionName <> " :: ClassName"
                , unFunctionName functionName <> " = ClassName \"" <> unOriginalName originalName <> "\""
                ]
            )
      & Text.intercalate "\n"
  in Text.unlines
    [ "-- | !!! DO NOT EDIT !!!"
    , "-- | this file was autogenerated by generate-halogen-generate-css-classes-tailwind"
    , ""
    , "module " <> moduleName <> " (" <> exports <> ") where"
    , ""
    , "import Halogen.HTML (ClassName(..))"
    , ""
    , functions
    ]

scopeNameToModuleName :: ScopeName -> Text
scopeNameToModuleName (ScopeName scopeName) = scopeName

writeTailwindClassesSet :: AppOptions -> [ScopeName] -> TailwindClasses -> IO ()
writeTailwindClassesSet appOptions parentScopes (TailwindClasses set map) = do
  let thisModuleName :: [Text] = [rootModuleName appOptions] <> fmap unScopeName parentScopes

  let fileName = output appOptions Turtle.</> (Filesystem.Path.concat $ fmap (Turtle.decodeString . toS) thisModuleName) Turtle.<.> "purs"

  putStrLn $ Turtle.encodeString fileName

  unless (null parentScopes) $ Turtle.mktree (Turtle.directory fileName)

  NonEmpty.nonEmpty (Set.toList set) &
    maybe (pure ())
    (\originalNames ->
      Turtle.writeTextFile fileName $ renderFileContent (Text.intercalate "." thisModuleName) originalNames
    )

  void $ Map.traverseWithKey
    (\scope scopedMap -> writeTailwindClassesSet appOptions (parentScopes <> [scope]) scopedMap)
    map

main :: IO ()
main = Turtle.sh $ do
  appOptions <- liftIO $ execParser appOptionsParserInfo

  cssFileContent <- liftIO $ Turtle.readTextFile (input appOptions)

  let classNames :: TailwindClasses = cssContentToTypes cssFileContent

  liftIO $ writeTailwindClassesSet appOptions [] classNames
