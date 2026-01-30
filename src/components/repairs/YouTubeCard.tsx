import { Play } from "lucide-react";

interface YouTubeCardProps {
  videoId: string;
  title: string;
}

export const YouTubeCard = ({ videoId, title }: YouTubeCardProps) => {
  const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`;
  const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

  return (
    <a
      href={videoUrl}
      target="_blank"
      rel="noopener noreferrer"
      className="group block"
    >
      <div className="bg-card border border-border rounded-lg overflow-hidden transition-all duration-300 hover:shadow-lg hover:border-primary/50">
        <div className="relative aspect-video">
          <img
            src={thumbnailUrl}
            alt={title}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-black/30 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
            <div className="w-16 h-16 bg-primary/90 rounded-full flex items-center justify-center">
              <Play className="w-8 h-8 text-primary-foreground ml-1" />
            </div>
          </div>
        </div>
        <div className="p-3">
          <h4 className="font-medium text-sm text-foreground group-hover:text-primary transition-colors line-clamp-2">
            {title}
          </h4>
        </div>
      </div>
    </a>
  );
};
