@echo off

set "INTEL_OPENVINO_DIR=F:\Programmation\openvino"
set "INTEL_OPENVINO_INSTALL_DIR=%INTEL_OPENVINO_DIR%\build\install"

:: OpenCV
if exist "%INTEL_OPENVINO_INSTALL_DIR%\opencv\setupvars.bat" (
call "%INTEL_OPENVINO_INSTALL_DIR%\opencv\setupvars.bat"
) else (
set "OpenCV_DIR=%INTEL_OPENVINO_INSTALL_DIR%\opencv\x64\vc14\lib"
set "PATH=%INTEL_OPENVINO_INSTALL_DIR%\opencv\x64\vc14\bin;%PATH%"
)

:: Model Optimizer
if exist %INTEL_OPENVINO_DIR%\model_optimizer (
set PYTHONPATH=%INTEL_OPENVINO_DIR%\model_optimizer;%PYTHONPATH%
set "PATH=%INTEL_OPENVINO_DIR%\model_optimizer;%PATH%"
)

:: Inference Engine
set "InferenceEngine_DIR=%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\share"
set "HDDL_INSTALL_DIR=%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\external\hddl"
set "PATH=%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\external\tbb\bin;%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\bin\intel64\Release;%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\bin\intel64\Debug;%HDDL_INSTALL_DIR%\bin;%PATH%"
if exist %INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\bin\intel64\arch_descriptions (
set ARCH_ROOT_DIR=%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\inference_engine\bin\intel64\arch_descriptions
)

:: nGraph
if exist %INTEL_OPENVINO_DIR%\build\ngraph (
set "PATH=%INTEL_OPENVINO_DIR%\bin\intel64\Release;%PATH%"
set "ngraph_DIR=%INTEL_OPENVINO_DIR%\build\ngraph"
)

:: Check if Python is installed
python --version 2>NUL
if errorlevel 1 (
   echo Error^: Python is not installed. Please install one of Python 3.6 - 3.8 ^(64-bit^) from https://www.python.org/downloads/
   exit /B 1
)

:: Check Python version
for /F "tokens=* USEBACKQ" %%F IN (`python --version 2^>^&1`) DO (
   set version=%%F
)

for /F "tokens=1,2,3 delims=. " %%a in ("%version%") do (
   set Major=%%b
   set Minor=%%c
)

if "%Major%" geq "3" (
   if "%Minor%" geq "6" (
      set python_ver=okay
   )
)

if not "%python_ver%"=="okay" (
   echo Unsupported Python version. Please install one of Python 3.6 - 3.8 ^(64-bit^) from https://www.python.org/downloads/
   exit /B 1
)

:: Check Python bitness
python -c "import sys; print(64 if sys.maxsize > 2**32 else 32)" 2 > NUL
if errorlevel 1 (
   echo Error^: Error during installed Python bitness detection
   exit /B 1
)

for /F "tokens=* USEBACKQ" %%F IN (`python -c "import sys; print(64 if sys.maxsize > 2**32 else 32)" 2^>^&1`) DO (
   set bitness=%%F
)

if not "%bitness%"=="64" (
   echo Unsupported Python bitness. Please install one of Python 3.6 - 3.8 ^(64-bit^) from https://www.python.org/downloads/
   exit /B 1
)

set PYTHONPATH=%INTEL_OPENVINO_INSTALL_DIR%\python\python%Major%.%Minor%;%INTEL_OPENVINO_INSTALL_DIR%\python\python3;%PYTHONPATH%

if exist %INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\open_model_zoo\tools\accuracy_checker (
    set PYTHONPATH=%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\open_model_zoo\tools\accuracy_checker;%PYTHONPATH%
)

if exist %INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\tools\post_training_optimization_toolkit (
    set PYTHONPATH=%INTEL_OPENVINO_INSTALL_DIR%\deployment_tools\tools\post_training_optimization_toolkit;%PYTHONPATH%
)

echo [setupvars.bat] OpenVINO environment initialized

:: Set fast pose extractor to PYTHON path (still not able to load pose_extractor.pyd -> DLL error)
set PYTHONPATH=pose_extractor\build;%PYTHONPATH%

:: Run demo with openvino
python demo.py --model .\human-pose-estimation-3d.xml --device CPU --use-openvino --video 0

exit /B 1