# story_creator

A package for creating instagram like story, you can use this package to edit images and make it story ready by adding other contents over it like text.

![Alt Text](https://raw.githubusercontent.com/mrgulshanyadav/story_designer/master/showcase.gif)

## Getting Started

Add this to your package's pubspec.yaml file:

```
dependencies:
  story_creator: ^1.0.0
```

## Use it like this

        File editedFile = await Navigator.of(context).push(
             MaterialPageRoute(builder: (context)=> StoryCreator(
              filePath: file.path,
            ))
        );
