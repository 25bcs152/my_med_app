import { cn } from "@/lib/utils";

export const Logo = ({ className, ...props }: React.SVGProps<SVGSVGElement>) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 200 120"
    className={cn("w-auto h-auto", className)}
    {...props}
  >
    <defs>
      <linearGradient id="redGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#d92e2e" />
        <stop offset="100%" stopColor="#a02121" />
      </linearGradient>
      <linearGradient id="greenGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#8BC34A" />
        <stop offset="100%" stopColor="#689F38" />
      </linearGradient>
      <linearGradient id="textGradient" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#d17a3a" />
        <stop offset="100%" stopColor="#9a4d21" />
      </linearGradient>
    </defs>
    
    {/* Hands */}
    <path
      d="M50 85 C 60 55, 100 65, 100 65 C 100 65, 140 55, 150 85 L 50 85 Z"
      fill="url(#greenGradient)"
      transform="translate(0, -15)"
    />
     <path
      d="M45,90 C 65,55 70,65 100,55 C 130,65 135,55 155,90 L 155,85 C 135,50 130,60 100,50 C 70,60 65,50 45,85 Z"
      fill="url(#greenGradient)"
      transform="translate(0, -15)"
    />

    {/* Family figures */}
    {/* Main large figure */}
    <circle cx="100" cy="28" r="12" fill="url(#redGradient)" />
    <path d="M85 38 C 85 58, 115 58, 115 38 Z" fill="url(#redGradient)" />

    {/* Left smaller figure */}
    <circle cx="83" cy="48" r="7" fill="#E57373" />
    <path d="M75 53 C 75 68, 91 68, 91 53 Z" fill="#E57373" />
    
    {/* Right smaller figure */}
    <circle cx="117" cy="43" r="8" fill="#d92e2e" />
    <path d="M108 50 C 108 68, 126 68, 126 50 Z" fill="#d92e2e" />

    {/* Smallest white figure */}
    <circle cx="118" cy="60" r="5" fill="white" />
    <path d="M112 64 C 112 76, 124 76, 124 64 Z" fill="white" />

    {/* Text */}
    <rect y="74" width="200" height="2" fill="#008000" />
    <circle cx="10" cy="75" r="3" fill="#d17a3a" />
    <circle cx="185" cy="75" r="3" fill="#d17a3a" />

    <text 
      x="98" 
      y="95" 
      fontFamily="serif" 
      fontSize="20" 
      fill="url(#textGradient)" 
      textAnchor="middle" 
      fontWeight="bold"
      letterSpacing="1"
    >
      jan aushadhi
    </text>

    <text 
      x="98" 
      y="108" 
      fontFamily="sans-serif" 
      fontSize="8" 
      fill="#404040" 
      textAnchor="middle"
    >
      Quality Medicines at Affordable Prices for All
    </text>

  </svg>
);
