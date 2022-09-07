export const COMMIT_HASH = __defines__.COMMIT_HASH as string;

export function sfmtaUrl(itemId: string, qr = false): string {
    return `${qr ? '' : 'https://www.'}sfmta.com/${itemId}?utm_source=${qr ? 'SSR' : 'SSR_WEB'}`;
}
