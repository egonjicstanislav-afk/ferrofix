// FerroFix — Edge Function: slanje mejl obaveštenja za novu narudžbinu
// Deploy: Supabase Dashboard → Edge Functions → New Function → "send-order-notification"
//
// Potrebni Secrets (Supabase → Project Settings → Edge Functions → Secrets):
//   RESEND_API_KEY   — API ključ sa resend.com
//   NOTIFY_FROM_EMAIL — npr. narudzbine@ferrofix.shop (mora biti verifikovan domen na Resend)
//                       ili ostaviti prazno → koristiće onboarding@resend.dev (samo za testiranje)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    const payload = await req.json();
    const order = payload.record;

    if (!order) {
      return new Response('Nema podataka o narudžbini', { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { data: emails } = await supabase
      .from('notification_emails')
      .select('email')
      .eq('active', true);

    if (!emails?.length) {
      return new Response('Nema aktivnih mejl adresa', { status: 200 });
    }

    const customer = order.customer || {};
    const delivery = order.delivery || {};
    const items = (order.items || [])
      .map((i: any) => `  • ${i.name} ×${i.qty} = ${(i.qty * i.price).toLocaleString('sr')} RSD`)
      .join('\n');

    const emailText = `
Nova narudžbina na FerroFix!

Broj: ${order.id}
Kupac: ${customer.name || '—'}
Telefon: ${customer.phone || '—'}
Adresa: ${customer.address || '—'}, ${customer.village || '—'}
Dostava: ${delivery.date || '—'} (${delivery.slotLabel || '—'})

Artikli:
${items}

UKUPNO: ${Number(order.total).toLocaleString('sr')} RSD
${customer.note ? `Napomena: ${customer.note}` : ''}

---
Upravljaj narudžbinama: https://ferrofix.shop/admin.html
    `.trim();

    const resendKey = Deno.env.get('RESEND_API_KEY');
    const fromEmail = Deno.env.get('NOTIFY_FROM_EMAIL') || 'onboarding@resend.dev';

    const allEmails = emails.map((e: any) => e.email);
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: `FerroFix <${fromEmail}>`,
        to: allEmails,
        subject: `🛒 Nova narudžbina ${order.id} — FerroFix`,
        text: emailText,
      }),
    });
    if (!res.ok) {
      console.error('Resend greška:', await res.text());
    }

    return new Response('OK', { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response('Error: ' + (err as Error).message, { status: 500 });
  }
});
