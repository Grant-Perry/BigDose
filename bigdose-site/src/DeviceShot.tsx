type DeviceShotProps = {
  src: string
  alt: string
  className?: string
  eager?: boolean
}

export function DeviceShot({ src, alt, className = '', eager = false }: DeviceShotProps) {
  return (
    <figure className={`device ${className}`.trim()}>
      <div className="device__notch" aria-hidden="true" />
      <img
        src={src}
        alt={alt}
        loading={eager ? 'eager' : 'lazy'}
        decoding="async"
        width={390}
        height={844}
      />
    </figure>
  )
}

export function WideShot({ src, alt }: { src: string; alt: string }) {
  return (
    <figure className="wide-shot" data-reveal>
      <img src={src} alt={alt} loading="lazy" decoding="async" />
    </figure>
  )
}
