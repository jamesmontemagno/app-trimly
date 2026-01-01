# SEO Best Practices for TrimTally Website

This document outlines the SEO strategies and best practices implemented on the TrimTally website to ensure optimal search engine visibility and discoverability.

## Overview

The TrimTally website has been optimized for search engines with a focus on:
- **Mobile-first indexing** - Fully responsive design
- **Semantic HTML** - Proper use of HTML5 elements and ARIA attributes
- **Structured data** - Rich snippets for better search results
- **Performance** - Fast loading times with optimized resources
- **Accessibility** - WCAG compliant for all users

## Meta Tags

### Primary Meta Tags

Located in `/website/index.html`:

```html
<title>TrimTally - Private Weight Tracking App for iOS & macOS | No Account Required</title>
<meta name="description" content="..." />
<meta name="keywords" content="weight tracking app, iOS weight tracker, ..." />
<meta name="robots" content="index, follow" />
<link rel="canonical" href="https://trimtally.app/" />
```

**Best Practices:**
- Keep title under 60 characters
- Keep description under 160 characters
- Update keywords as features evolve
- Always include canonical URL to prevent duplicate content

### Open Graph Tags

For social media sharing (Facebook, LinkedIn, etc.):

```html
<meta property="og:type" content="website" />
<meta property="og:title" content="TrimTally - Private Weight Tracking App for iOS & macOS" />
<meta property="og:description" content="..." />
<meta property="og:image" content="https://trimtally.app/app-icon.png" />
```

**Best Practices:**
- Use PNG/JPG images (not SVG) for og:image
- Image dimensions: 1200x630px for best results
- Always include og:image:alt for accessibility
- Test social previews with Facebook Sharing Debugger and Twitter Card Validator

### Twitter Cards

For Twitter sharing:

```html
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:creator" content="@JamesMontemagno" />
```

**Best Practices:**
- Use `summary_large_image` for better visibility
- Update creator handle if changed
- Test with Twitter Card Validator

## Structured Data (Schema.org)

Three JSON-LD schemas are implemented:

### 1. MobileApplication Schema

Primary schema for the app listing:

```json
{
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "name": "TrimTally",
  "applicationCategory": "HealthApplication",
  "operatingSystem": "iOS 17.0+, macOS 14.0+",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "aggregateRating": { ... },
  "featureList": [ ... ]
}
```

**Update when:**
- App version changes
- New features are added
- Rating/review count changes (add aggregateRating when you have genuine reviews)
- Pricing model changes

**Note on Ratings:**
The aggregateRating field has been intentionally omitted until genuine user reviews are available. When you accumulate real App Store reviews, add the aggregateRating object:
```json
"aggregateRating": {
  "@type": "AggregateRating",
  "ratingValue": "4.8",
  "bestRating": "5",
  "ratingCount": "150"
}
```
Only include ratings with a meaningful number of reviews (at least 10+) to maintain credibility with search engines.

### 2. WebSite Schema

General website information:

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "TrimTally",
  "url": "https://trimtally.app/"
}
```

### 3. SoftwareApplication Schema

Alternative app schema for broader coverage:

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "TrimTally",
  "applicationCategory": "HealthApplication"
}
```

**Testing:**
- Use Google's Rich Results Test: https://search.google.com/test/rich-results
- Validate with Schema.org validator

## Technical SEO Files

### robots.txt

Location: `/website/public/robots.txt`

```
User-agent: *
Allow: /
Sitemap: https://trimtally.app/sitemap.xml
```

**Best Practices:**
- Keep it simple and permissive
- Always reference sitemap.xml
- Update when adding new restricted areas

### sitemap.xml

Location: `/website/public/sitemap.xml`

Contains:
- Main landing page (priority: 1.0)
- Privacy policy (priority: 0.6)
- Terms of service (priority: 0.6)
- Image sitemaps for screenshots

**Best Practices:**
- Update `<lastmod>` when content changes
- Add new pages as they're created
- Set appropriate priorities (0.0-1.0)
- Include mobile annotation with `<mobile:mobile/>`
- Submit to Google Search Console after updates

### humans.txt

Location: `/website/public/humans.txt`

Credits the team and lists technologies used. Good for:
- Team attribution
- Technology discovery
- Community engagement

**Update when:**
- Team members change
- Technology stack updates
- Major releases

## Semantic HTML & Accessibility

### ARIA Roles & Labels

All interactive elements have proper ARIA attributes:

```tsx
<header role="banner">
<nav role="navigation" aria-label="Main navigation">
<main role="main">
<footer role="contentinfo">
```

**Best Practices:**
- Use semantic HTML5 elements first (header, nav, main, footer, article, section)
- Add ARIA labels for screen readers
- Use `aria-hidden="true"` for decorative icons
- Add `aria-label` to all buttons and links without visible text

### Image Alt Text

All images have descriptive alt text:

```tsx
<img 
  src="..." 
  alt="TrimTally dashboard screen showing weight tracking overview"
  loading="lazy"
/>
```

**Best Practices:**
- Describe what's in the image, not "image of..."
- Include keywords naturally
- Use empty alt="" for decorative images
- Add loading="lazy" for below-the-fold images

### Heading Hierarchy

Proper H1-H6 structure:

```
H1: Main page title (once per page)
├── H2: Major sections
│   ├── H3: Subsections
│   └── H3: Subsections
```

**Best Practices:**
- Only one H1 per page
- Don't skip heading levels
- Use headings for structure, not styling

## Performance Optimization

### Resource Hints

```html
<link rel="preconnect" href="https://apps.apple.com" crossorigin />
<link rel="dns-prefetch" href="https://apps.apple.com" />
```

**Best Practices:**
- Preconnect to critical third-party domains
- DNS prefetch for less critical resources
- Don't overuse (max 3-4 domains)

### Image Optimization

- Use WebP/AVIF when possible
- Add width/height attributes to prevent layout shift
- Use lazy loading for below-the-fold images
- Optimize PNG/JPG with compression tools

## Content Strategy

### Keywords

Primary keywords:
- weight tracking app
- iOS weight tracker
- private weight tracking
- Apple Health integration
- HealthKit weight tracker

Secondary keywords:
- weight loss app
- fitness tracker
- health app iOS
- goal tracking app
- weight analytics

**Best Practices:**
- Use keywords naturally in content
- Include in headings when relevant
- Add to image alt text
- Update based on search trends

### Content Updates

Regularly update:
- Version numbers in schemas
- Feature lists as new features launch
- Screenshots to show latest UI
- Ratings/reviews data
- Last modified dates in sitemap

## Monitoring & Maintenance

### Tools to Use

1. **Google Search Console**
   - Submit sitemap
   - Monitor indexing status
   - Check for errors
   - View search analytics

2. **Google Analytics** (if/when added)
   - Track user behavior
   - Monitor traffic sources
   - Analyze conversions

3. **Testing Tools**
   - Google Rich Results Test
   - Facebook Sharing Debugger
   - Twitter Card Validator
   - Lighthouse (Chrome DevTools)
   - WebPageTest.org

### Regular Tasks

**Monthly:**
- Check Search Console for errors
- Update ratings/reviews in schemas
- Review and update keywords
- Check for broken links

**Quarterly:**
- Update sitemap with new pages
- Refresh screenshots if UI changed
- Review and update meta descriptions
- Analyze search performance

**Yearly:**
- Complete SEO audit
- Update all schemas
- Refresh humans.txt
- Review and update all documentation

## Common Issues & Solutions

### Issue: Pages not indexing

**Solutions:**
- Verify robots.txt isn't blocking
- Submit sitemap to Search Console
- Check for canonical issues
- Ensure proper meta robots tags

### Issue: Poor social media previews

**Solutions:**
- Verify og:image is accessible
- Check image dimensions (1200x630)
- Use PNG/JPG, not SVG
- Clear cache with debugger tools

### Issue: Low search rankings

**Solutions:**
- Improve page speed
- Add more relevant content
- Build backlinks
- Update keywords based on research
- Enhance user engagement metrics

## Future Enhancements

Consider adding:
- **FAQ Schema** - If adding FAQ section
- **Review Schema** - When accumulating user reviews
- **Video Schema** - If adding demo videos
- **Breadcrumb Schema** - If adding multi-level navigation
- **Local Business Schema** - If relevant
- **hreflang tags** - For Spanish and French versions of the site

## Resources

- [Google Search Central](https://developers.google.com/search)
- [Schema.org Documentation](https://schema.org)
- [Open Graph Protocol](https://ogp.me/)
- [Twitter Card Documentation](https://developer.twitter.com/en/docs/twitter-for-websites/cards)
- [MDN Web Docs - SEO](https://developer.mozilla.org/en-US/docs/Glossary/SEO)
- [Google PageSpeed Insights](https://pagespeed.web.dev/)

---

**Last Updated:** December 25, 2025
**Maintained By:** TrimTally Development Team
