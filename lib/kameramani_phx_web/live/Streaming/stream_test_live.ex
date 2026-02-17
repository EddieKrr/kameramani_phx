defmodule KameramaniPhxWeb.Streaming.StreamTestLive do
  use KameramaniPhxWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-gray-100 p-4">
      <h1 class="text-3xl font-bold mb-6">Membrane HLS Stream Test</h1>

      <div class="w-full max-w-4xl bg-white rounded-lg shadow-md overflow-hidden">
        <video id="hls-video" controls class="w-full"></video>
      </div>

      <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
      <script>
        if(Hls.isSupported()) {
          var video = document.getElementById('hls-video');
          var hls = new Hls();
          // Assuming your HLS manifest is served at /live/cube/index.m3u8
          hls.loadSource('/live/cube/index.m3u8');
          hls.attachMedia(video);
          hls.on(Hls.Events.MANIFEST_PARSED, function() {
            video.play();
          });
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = '/live/cube/index.m3u8';
          video.addEventListener('loadedmetadata', function() {
            video.play();
          });
        }
      </script>
    </div>
    """
  end
end
