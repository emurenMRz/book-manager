import * as React from "react";

export default function BookImage(props: { isbn: string, alt: string }) {
	const refImage = React.createRef<HTMLImageElement>();
	const imageSrc = `cache/${props.isbn}.jpg`;

	React.useEffect(() => {
		const observer = new IntersectionObserver((entries: any) => {
			entries.forEach((entry: any) => {
				if (!entry.intersectionRatio) return;
				entry.target.src = entry.target.dataset.src;
				observer.unobserve(entry.target);
			});
		});
		observer.observe(refImage.current!);
	}, [imageSrc]);

	return <div className="book-image"><img ref={refImage} data-src={imageSrc} alt={props.alt} /></div>;
}