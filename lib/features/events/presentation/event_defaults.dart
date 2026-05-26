import 'dart:math';

const commonEventImageUrl =
    'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1200&q=80&sat=-100';

const eventImageUrls = [
    'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1521334884684-d80222895322?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1200&q=80&sat=-100',
    'https://images.unsplash.com/photo-1485871981521-5b6d0f2a6d75?auto=format&fit=crop&w=1200&q=80&sat=-100',
];

String pickRandomEventImageUrl([Random? random]) {
    final rng = random ?? Random();
    return eventImageUrls[rng.nextInt(eventImageUrls.length)];
}