{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Evita los errores WebGL/Shader y el fallo del stencil buffer
    // en equipos donde CanvasKit no puede inicializar correctamente.
    canvasKitForceCpuOnly: true,
  },
});
