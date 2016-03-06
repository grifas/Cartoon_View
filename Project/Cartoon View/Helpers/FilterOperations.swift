import Foundation
import GPUImage
import QuartzCore

#if os(iOS)
  import OpenGLES
#else
  import OpenGL
#endif

let filterOperations: Array<FilterOperationInterface> = [
  FilterOperation <GPUImageSmoothToonFilter>(
    listName:"Smooth toon",
    titleName:"Smooth Toon",
    sliderConfiguration:.Enabled(minimumValue:1.0, maximumValue:6.0, initialValue:1.0),
    sliderUpdateCallback: {(filter, sliderValue) in
      filter.blurRadiusInPixels = sliderValue
    },
    filterOperationType:.SingleInput
  ),
  
  //    GPUIMAGE_OPACITY,
  //    GPUIMAGE_CUSTOM,
  //    GPUIMAGE_UIELEMENT,
  //    GPUIMAGE_FILECONFIG,
  //    GPUIMAGE_FILTERGROUP,
  //    GPUIMAGE_FACES,
]