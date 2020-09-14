#include <mex.h>
#include "GLEW/glew.h"
#include "GLFW/glfw3.h"

GLFWwindow *windows[100];
mwSize numWindows;
int keyPressed = -1;
int keyReleased = -1;
int modifiers = -1;
int buttonPressed = -1;
int buttonReleased = -1;
int activeWindow = -1;

static const GLsizeiptr NUM_BUFFERS = 3;
GLuint vertexBufferID = 0;
GLuint colorBufferID = 0;
GLuint triangleBufferID = 0;
GLuint primitivesArrayID = 0;
GLsizei vertexBufferSize = -1;
GLsizei triangleBufferSize = -1;

struct GBufferRange {
  GLfloat*  vertex;
  GLubyte*  color;
  GLuint*   triangle;
  GLuint    indexOffset;
  void*     triOffset;
  GLsync    gSync;
};
GBufferRange bufferRange[NUM_BUFFERS];
int bufferIndex = 0;


static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (action == GLFW_PRESS) {
        keyPressed = key;
        modifiers = mods;
    }
    else if (action == GLFW_RELEASE) {
        keyReleased = key;
        modifiers = mods;
    }
}

static void mouse_callback(GLFWwindow* window, int button, int action, int mods)
{
    int i;
    
    if (action == GLFW_PRESS) {
        buttonPressed = button;
        modifiers = mods;
    }
    if (action == GLFW_RELEASE) {
        buttonReleased = button;
        modifiers = mods;
    }
    for (i = 0; i < numWindows; i++) {
        if (windows[i] == window) {
            activeWindow = i;
        }
    }
}

static void lock_buffer(GLsync& gSync)
{
  if (gSync)  glDeleteSync(gSync);
  gSync = glFenceSync( GL_SYNC_GPU_COMMANDS_COMPLETE, 0 );
}

static void wait_buffer(GLsync& gSync)
{
  if (!gSync) return;
  while (true) {
    GLenum  waitReturn  = glClientWaitSync(gSync, GL_SYNC_FLUSH_COMMANDS_BIT, 1);
    if (waitReturn == GL_ALREADY_SIGNALED || waitReturn == GL_CONDITION_SATISFIED)
      return;
  }
}

static void delete_buffers()
{
  // Release buffers
  if (vertexBufferID > 0) {
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
    glUnmapBuffer(GL_ARRAY_BUFFER);
    glDeleteBuffers(1, &vertexBufferID);
    vertexBufferID = 0;
  }
  if (colorBufferID > 0) {
    glBindBuffer(GL_ARRAY_BUFFER, colorBufferID);
    glUnmapBuffer(GL_ARRAY_BUFFER);
    glDeleteBuffers(1, &colorBufferID);
    colorBufferID = 0;
  }
  if (triangleBufferID > 0) {
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleBufferID);
    glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
    glDeleteBuffers(1, &triangleBufferID);
    triangleBufferID = 0;
  }
  if (primitivesArrayID > 0) {
    glDeleteVertexArrays(1, &primitivesArrayID);
    primitivesArrayID = 0;
  }

  for (int iBuf = 0; iBuf < NUM_BUFFERS; ++iBuf) {
    bufferRange[iBuf].vertex      = 0;
    bufferRange[iBuf].triangle    = 0;
    bufferRange[iBuf].indexOffset = 0;
    bufferRange[iBuf].triOffset   = 0;
    bufferRange[iBuf].gSync       = 0;
  }

  vertexBufferSize = -1;
  triangleBufferSize = -1;
  bufferIndex = 0;
}

static void terminate()
{
  delete_buffers();
  glfwTerminate();
}


void allocate_buffers(const mxArray* vertices, const mxArray* triangles, const mxArray* colors)
{
  const mwSize* vertexDim     = mxGetDimensions(vertices);
  const mwSize* triangleDim   = mxGetDimensions(triangles);

  GLsizei       numVertices   = vertexDim[1];
  GLsizei       numTriangles  = triangleDim[1];
  const GLsizei nColorDims    = mxGetM(colors);
  if (mxGetN(colors) != numVertices)
    mexErrMsgIdAndTxt("virmenOpenGLRoutines:allocate_buffers"
                      , "Number of colors (%d) must be equal to the number of vertices (%d)"
                      , mxGetN(colors), numVertices);

  // Size in bytes to use for buffer allocation
  GLsizei totVertices   = vertexDim[0] * vertexDim[1];        // 3rd dimension is by window
  GLsizei totTriangles  = triangleDim[0] * triangleDim[1];
  GLsizei vertexSize    = totVertices  * sizeof(GLfloat) / sizeof(GLubyte);
  GLsizei triangleSize  = totTriangles * sizeof(GLuint)  / sizeof(GLubyte);
  GLsizei colorSize     = numVertices  * nColorDims;

  // If we already have buffers of the correct size, nothing to do
  if (vertexSize <= vertexBufferSize && triangleSize <= triangleBufferSize)
    return;

  // Otherwise we will reallocate buffers and should store the new sizes
  vertexBufferSize      = vertexSize;
  triangleBufferSize    = triangleSize;
  mexPrintf("virmenOpenGLRoutines:  Reallocating graphics buffers for %d vertices and %d triangles.\n", numVertices, numTriangles);

  // Wait for GPU to be done with buffers so that we can delete them
  for (int iBuf = 0; iBuf < NUM_BUFFERS; ++iBuf)
    wait_buffer(bufferRange[iBuf].gSync);
  delete_buffers();


  static const GLbitfield bufferHints = GL_MAP_WRITE_BIT
                                      | GL_MAP_PERSISTENT_BIT
                                      | GL_MAP_COHERENT_BIT
                                      ;

  // Setup VAO and associate the relevant attributes
  glGenVertexArrays(1, &primitivesArrayID);
  glBindVertexArray(primitivesArrayID);

  // Vertices
  glGenBuffers(1, &vertexBufferID);
  glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
  glBufferStorage(GL_ARRAY_BUFFER, NUM_BUFFERS*vertexSize, NULL, bufferHints);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
  GLfloat* vertexBuffer = (GLfloat*) glMapBufferRange(GL_ARRAY_BUFFER, 0, NUM_BUFFERS*vertexSize, bufferHints);
          
  // Vertex and color indices must be identical
  glGenBuffers(1, &colorBufferID);
  glBindBuffer(GL_ARRAY_BUFFER, colorBufferID);
  glBufferStorage(GL_ARRAY_BUFFER, NUM_BUFFERS*colorSize, NULL, bufferHints);
  glEnableVertexAttribArray(3);
  glVertexAttribPointer(3, nColorDims, GL_UNSIGNED_BYTE, GL_TRUE, 0, 0);
  GLubyte* colorBuffer  = (GLubyte*) glMapBufferRange(GL_ARRAY_BUFFER, 0, NUM_BUFFERS*colorSize, bufferHints);

  // Triangles (vertex indices)
  glGenBuffers(1, &triangleBufferID);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleBufferID);
  glBufferStorage(GL_ELEMENT_ARRAY_BUFFER, NUM_BUFFERS*triangleSize, NULL, bufferHints);
  GLuint* triangleBuffer = (GLuint*) glMapBufferRange(GL_ELEMENT_ARRAY_BUFFER, 0, NUM_BUFFERS*triangleSize, bufferHints);
          
  //glBindVertexArray(0);

  for (int iBuf = 0; iBuf < NUM_BUFFERS; ++iBuf) {
    bufferRange[iBuf].vertex      = vertexBuffer    + iBuf * totVertices ;
    bufferRange[iBuf].color       = colorBuffer     + iBuf * colorSize;
    bufferRange[iBuf].triangle    = triangleBuffer  + iBuf * totTriangles;
    bufferRange[iBuf].indexOffset = iBuf * numVertices;
    bufferRange[iBuf].triOffset   = (void*) ( iBuf * triangleSize );
  }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int command;
    int dummy;
    int width, height;
    int xpos, ypos;
    int antialiasing;
    double aspectRatio;
    double *windowInfo;
    const GLFWvidmode *mode;
    GLdouble *surfaceVertices;
    GLuint *surfaceIndices;
    GLdouble *surfaceColors;
    GLdouble *lineVertices;
    GLuint *lineIndices;
    GLdouble *lineColors;
    mwSize colorSize;
    double *currentKey, *currentKeyReleased, *currentButton, *currentButtonReleased, *currentModifiers, *cursorPosition, *currentWindow;
    double *background;
    double *colorSize3;
    int i;
    int wind, transformation, numVertices,numTriangles;
    double isMac;
    double *data;
    int dims[2];
    
    command = mxGetScalar(prhs[0]);

    // Initialize window
    if (command == 0) {
        // Call cleanup code just in case the previous round was not terminated properly
        terminate();
      
        // Register OpenGL termination to occur on Matlab exit
        mexAtExit(terminate);
        
        // Create new OpenGL window
        dummy = glfwInit();
        
        // Read in windows information
        windowInfo = mxGetPr(prhs[1]);
        numWindows = mxGetN(prhs[1]);
        
        // Do some things differently if this is a Mac.
        isMac = mxGetScalar(prhs[2]);
        
        for (i = 0; i < numWindows; i++) {
            // Create new windows
            // Set antialiasing
            antialiasing = windowInfo[5*i+4];
            glfwWindowHint(GLFW_SAMPLES, antialiasing);
            
            glfwWindowHint(GLFW_DECORATED, GL_FALSE);
            width = windowInfo[5*i+2];
            height = windowInfo[5*i+3];
            windows[i] = glfwCreateWindow(width, height, "ViRMEn", NULL, NULL);
            
            glfwMakeContextCurrent(windows[i]);
            
            // Initialize OpenGL extensions for this context
            GLenum glewStatus = glewInit();
            if (glewStatus != GLEW_OK)
              mexErrMsgIdAndTxt("virmenOpenGLRoutines:init", "Failed to initialize GLEW for window %d, error: %s", i, glewGetErrorString(glewStatus));

            glfwGetFramebufferSize(windows[i], &width, &height);
            glfwSwapInterval(1);
            glViewport(0, 0, width, height);
            
            xpos = windowInfo[5*i];
            ypos = windowInfo[5*i+1];
            glfwSetWindowPos(windows[i], xpos, ypos);
            
            // Callbacks for keyboard press and mouse clicks
            glfwSetKeyCallback(windows[i], key_callback);
            glfwSetMouseButtonCallback(windows[i], mouse_callback);
            
            // Initialize OpenGL properties
            aspectRatio = (double)width / (double)height;
            glOrtho(-aspectRatio, aspectRatio, -1, 1, -1000, 0);  // orthographic projection
            glEnable(GL_DEPTH_TEST);  // enable depth (for object occlusion)
            glClearDepth(-1.0);
            glDepthFunc(GL_GEQUAL);
            glShadeModel(GL_FLAT);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            
            if (!isMac) {
                glfwIconifyWindow(windows[i]);
                glfwRestoreWindow(windows[i]);
            }
        }

        keyPressed = -1;
        keyReleased = -1;
        modifiers = -1;
        buttonPressed = -1;
        buttonReleased = -1;
        activeWindow = -1;
    }
    
    // Render
    else if (command == 1) {
        // Get surface arrays from Matlab
        surfaceVertices = (GLdouble *)mxGetData(prhs[1]);
        surfaceIndices = (GLuint *)mxGetData(prhs[2]);
        surfaceColors = (GLdouble *)mxGetData(prhs[3]);
        
        // Get line arrays from Matlab
        lineVertices = (GLdouble *)mxGetData(prhs[4]);
        lineIndices = (GLuint *)mxGetData(prhs[5]);
        lineColors = (GLdouble *)mxGetData(prhs[6]);
        
        wind = mxGetScalar(prhs[7]);
        transformation = mxGetScalar(prhs[8]);
        numVertices = mxGetScalar(prhs[9]);
        numTriangles = mxGetScalar(prhs[10]);
        const int worldChanged = mxGetScalar(prhs[11]) > 0;
        const int iTransform = static_cast<int>( transformation-1 );

        // Ensure sufficient buffer size if geometry has changed
        if (worldChanged)   allocate_buffers(prhs[1], prhs[2], prhs[3]);

        
        glfwMakeContextCurrent(windows[wind-1]);
        
        // Clear the screen
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // Determine size of the surface color matrix
        colorSize = mxGetNumberOfElements(prhs[3]);

        // Wait until GPU is no longer using buffers
        wait_buffer(bufferRange[bufferIndex].gSync);

        GLdouble* vertices = surfaceVertices + numVertices*iTransform;
        for (int iVtx = 0; iVtx < numVertices; ++iVtx, ++vertices)
          bufferRange[bufferIndex].vertex[iVtx]   = float( *vertices );

        GLdouble* colors = surfaceColors;
        for (int iClr = 0; iClr < colorSize; ++iClr, ++colors)
          bufferRange[bufferIndex].color[iClr]    = static_cast<GLubyte>((*colors) * 255);

        GLuint* indices = surfaceIndices + numTriangles*iTransform;
        for (int iTri = 0; iTri < numTriangles; ++iTri, ++indices)
          bufferRange[bufferIndex].triangle[iTri] = (*indices) + bufferRange[bufferIndex].indexOffset;

        //glBindVertexArray(primitivesArrayID);
        //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleBufferID);

        glDrawElements(GL_TRIANGLES, numTriangles, GL_UNSIGNED_INT, bufferRange[bufferIndex].triOffset);
        //glDrawElementsBaseVertex(GL_TRIANGLES, numTriangles, GL_UNSIGNED_INT, bufferRange[bufferIndex].triOffset, bufferRange[bufferIndex].indexOffset);

        lock_buffer(bufferRange[bufferIndex].gSync);
        bufferIndex = (bufferIndex + 1) % NUM_BUFFERS;
        

        //// Determine size of the line color matrix
        //colorSize = mxGetM(prhs[6]);
        //
        //if (colorSize > 0) { // only if any lines exist
        //    // Point OpenGL to the line arrays
        //    glColorPointer(3, GL_DOUBLE, 0, lineColors);
        //    //glVertexPointer(2, GL_DOUBLE, 0, lineVertices);
        //    
        //    // Render the lines
        //    glDrawElements(GL_LINES, mxGetNumberOfElements(prhs[5]), GL_UNSIGNED_INT, lineIndices);
        //}
        
        // Let GPU work on this window
        glFlush();

        
        // Return current pressed key
        glfwPollEvents();
        plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
        currentKey = mxGetPr(plhs[0]);
        
        currentKey[0] = keyPressed;
        for (i = 0; i < numWindows; i++) {
            if (glfwWindowShouldClose(windows[i])) {
                currentKey[0] = 256;
            }
        }
        keyPressed = -1;
        
        // Return current clicked mouse button
        plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
        currentKeyReleased = mxGetPr(plhs[1]);
        currentKeyReleased[0] = keyReleased;
        keyReleased = -1;
        
        // Return current clicked mouse button
        plhs[2] = mxCreateDoubleMatrix(1, 1, mxREAL);
        currentButton = mxGetPr(plhs[2]);
        currentButton[0] = buttonPressed;
        buttonPressed = -1;
        
        // Return current clicked mouse button
        plhs[3] = mxCreateDoubleMatrix(1, 1, mxREAL);
        currentButtonReleased = mxGetPr(plhs[3]);
        currentButtonReleased[0] = buttonReleased;
        buttonReleased = -1;
        
        // Return modifier keys that are currently pressed
        plhs[4] = mxCreateDoubleMatrix(1, 1, mxREAL);
        currentModifiers = mxGetPr(plhs[4]);
        currentModifiers[0] = modifiers;
        modifiers = -1;
        
        // Return current window
        plhs[5] = mxCreateDoubleMatrix(1, 1, mxREAL);
        currentWindow = mxGetPr(plhs[5]);
        currentWindow[0] = activeWindow;
        activeWindow = -1;
        
        // Return cursor position
        plhs[6] = mxCreateDoubleMatrix(1, 2, mxREAL);
        cursorPosition = mxGetPr(plhs[6]);
        glfwGetCursorPos(windows[wind-1], &(cursorPosition[0]), &(cursorPosition[1]));


        // Swap buffers at the end since this blocks until the next vsync
        glfwSwapBuffers(windows[wind-1]);
    }
    
    // Terminate window
    else if (command == 2) {
        // Destroy window
        for (i = 0; i < numWindows; i++) {
            glfwDestroyWindow(windows[i]);
        }
        
        // Delete buffers and terminate GLFW
        terminate();
    }
    
    // Change transparency
    else if (command == 3) {
        // Get color matrix size (3 or 4) from Matlab
        colorSize3 = mxGetPr(prhs[1]);
        for (i = 0; i < numWindows; i++) {
            glfwMakeContextCurrent(windows[i]);
            if (colorSize3[0] == 3) {
                glDisable(GL_BLEND);
            }
            if (colorSize3[0] == 4) {
                glEnable(GL_BLEND);
            }
        }
        glFlush();
        glfwPollEvents();
    }
    
    // Change background color
    else if (command == 4) {
        // Get background color
        background = mxGetPr(prhs[1]);
        for (i = 0; i < numWindows; i++) {
            glfwMakeContextCurrent(windows[i]);
            glClearColor(background[0], background[1], background[2], 0.0);
        }
        glFlush();
        glfwPollEvents();
    }
    
    // Get pixel data
    else if (command == 5) {
        wind = mxGetScalar(prhs[1]);
        glfwMakeContextCurrent(windows[wind-1]);
        glfwGetFramebufferSize(windows[wind-1], &width, &height);
        
        // allocate space to store the pixels
        dims[0] = 3;
        dims[1] = width;
        dims[2] = height;
        plhs[0] = mxCreateNumericArray(3, dims, mxSINGLE_CLASS, mxREAL);
        
        data = mxGetPr(plhs[0]);
        
        glReadPixels(0, 0, width, height, GL_RGB, GL_FLOAT, data);
      
    }

}