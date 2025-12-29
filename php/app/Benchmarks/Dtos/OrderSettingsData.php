<?php

namespace App\Benchmarks\Dtos;

/**
 * ORDER SETTINGS DTO
 *
 * Maps the settings_json column from orders.
 * This is one of the LARGEST and most complex DTOs - 48+ nested objects.
 *
 * SWIFT IMPLEMENTATION:
 * ```swift
 * struct OrderSettings: Codable {
 *     let user: UserData?
 *     let deliveryAddress: AddressData?
 *     let invoiceAddress: AddressData?
 *     let costs: CostsData?
 *     let event: EventData?
 *     let latch: LatchData?
 *     let piggy: PiggyData?
 *     let backup: BackupData?
 *     let stripe: StripeData?
 *     let payu: PayuData?
 *     let sibs: SibsData?
 *     let adyen: AdyenData?
 *     // ... 40+ more fields
 * }
 * ```
 */
class OrderSettingsData
{
    public ?UserData $user = null;
    public ?AddressData $deliveryAddress = null;
    public ?AddressData $invoiceAddress = null;
    public ?CostsData $costs = null;
    public ?EventData $event = null;
    public ?LatchData $latch = null;
    public ?PiggyData $piggy = null;
    public ?BackupData $backup = null;
    public ?StripeData $stripe = null;
    public ?PayuData $payu = null;
    public ?SibsData $sibs = null;
    public ?AdyenData $adyen = null;
    public ?UrlsData $urls = null;
    public ?AdelyaData $adelya = null;
    public ?EdenredData $edenred = null;
    public ?MonizzeData $monizze = null;
    public ?ParcifyData $parcify = null;
    public ?PayconiqData $payconiq = null;
    public ?JoynBadgeData $joynBadge = null;
    public ?ExtraInfoData $extra_info = null;
    public ?StatisticsData $statistics = null;
    public ?WarrantyData $warranty = null;
    public ?XerxesData $xerxes = null;
    public ?WebpayData $webpay = null;

    public function __construct(array $data = [])
    {
        if (isset($data['user'])) {
            $this->user = new UserData($data['user']);
        }
        if (isset($data['deliveryAddress'])) {
            $this->deliveryAddress = new AddressData($data['deliveryAddress']);
        }
        if (isset($data['invoiceAddress'])) {
            $this->invoiceAddress = new AddressData($data['invoiceAddress']);
        }
        if (isset($data['costs'])) {
            $this->costs = new CostsData($data['costs']);
        }
        if (isset($data['event'])) {
            $this->event = new EventData($data['event']);
        }
        if (isset($data['latch'])) {
            $this->latch = new LatchData($data['latch']);
        }
        if (isset($data['piggy'])) {
            $this->piggy = new PiggyData($data['piggy']);
        }
        if (isset($data['backup'])) {
            $this->backup = new BackupData($data['backup']);
        }
        if (isset($data['stripe'])) {
            $this->stripe = new StripeData($data['stripe']);
        }
        if (isset($data['payu'])) {
            $this->payu = new PayuData($data['payu']);
        }
        if (isset($data['sibs'])) {
            $this->sibs = new SibsData($data['sibs']);
        }
        if (isset($data['adyen'])) {
            $this->adyen = new AdyenData($data['adyen']);
        }
        if (isset($data['urls'])) {
            $this->urls = new UrlsData($data['urls']);
        }
        if (isset($data['adelya'])) {
            $this->adelya = new AdelyaData($data['adelya']);
        }
        if (isset($data['edenred'])) {
            $this->edenred = new EdenredData($data['edenred']);
        }
        if (isset($data['monizze'])) {
            $this->monizze = new MonizzeData($data['monizze']);
        }
        if (isset($data['parcify'])) {
            $this->parcify = new ParcifyData($data['parcify']);
        }
        if (isset($data['payconiq'])) {
            $this->payconiq = new PayconiqData($data['payconiq']);
        }
        if (isset($data['joynBadge'])) {
            $this->joynBadge = new JoynBadgeData($data['joynBadge']);
        }
        if (isset($data['extra_info'])) {
            $this->extra_info = new ExtraInfoData($data['extra_info']);
        }
        if (isset($data['statistics'])) {
            $this->statistics = new StatisticsData($data['statistics']);
        }
        if (isset($data['warranty'])) {
            $this->warranty = new WarrantyData($data['warranty']);
        }
        if (isset($data['xerxes'])) {
            $this->xerxes = new XerxesData($data['xerxes']);
        }
        if (isset($data['webpay'])) {
            $this->webpay = new WebpayData($data['webpay']);
        }
    }
}

class UserData
{
    public string $email = '';
    public string $tin_nr = '';
    public string $lastname = '';
    public string $firstname = '';
    public string $telephone = '';
    public ?int $user_id = null;

    public function __construct(array $data = [])
    {
        $this->email = $data['email'] ?? '';
        $this->tin_nr = $data['tin_nr'] ?? '';
        $this->lastname = $data['lastname'] ?? '';
        $this->firstname = $data['firstname'] ?? '';
        $this->telephone = $data['telephone'] ?? '';
        $this->user_id = $data['user_id'] ?? null;
    }
}

class AddressData
{
    public string $street = '';
    public string $nr = '';
    public string $zipcode = '';
    public string $city = '';
    public string $country = '';
    public bool $enable = false;

    public function __construct(array $data = [])
    {
        $this->street = $data['street'] ?? '';
        $this->nr = $data['nr'] ?? '';
        $this->zipcode = $data['zipcode'] ?? '';
        $this->city = $data['city'] ?? '';
        $this->country = $data['country'] ?? '';
        $this->enable = $data['enable'] ?? false;
    }
}

class CostsData
{
    public float $sms = 0;

    public function __construct(array $data = [])
    {
        $this->sms = (float) ($data['sms'] ?? 0);
    }
}

class EventData
{
    public int $order_nr = 0;

    public function __construct(array $data = [])
    {
        $this->order_nr = $data['order_nr'] ?? 0;
    }
}

class LatchData
{
    public string $notification_method = '';

    public function __construct(array $data = [])
    {
        $this->notification_method = $data['notification_method'] ?? '';
    }
}

class PiggyData
{
    public ?PiggyQrData $qr = null;
    public bool $sent = false;
    public string $card_number = '';

    public function __construct(array $data = [])
    {
        if (isset($data['qr'])) {
            $this->qr = new PiggyQrData($data['qr']);
        }
        $this->sent = $data['sent'] ?? false;
        $this->card_number = $data['card_number'] ?? '';
    }
}

class PiggyQrData
{
    public ?int $id = null;
    public string $url = '';
    public string $hash = '';

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? null;
        $this->url = $data['url'] ?? '';
        $this->hash = $data['hash'] ?? '';
    }
}

class BackupData
{
    public ?int $shop_id = null;
    public string $shop_name = '';

    public function __construct(array $data = [])
    {
        $this->shop_id = $data['shop_id'] ?? null;
        $this->shop_name = $data['shop_name'] ?? '';
    }
}

class StripeData
{
    public string $payment_intent_id = '';

    public function __construct(array $data = [])
    {
        $this->payment_intent_id = $data['payment_intent_id'] ?? '';
    }
}

class PayuData
{
    public ?PayuVoidData $void = null;
    public ?PayuBrazilData $brazil = null;
    public ?string $auth_token = null;

    public function __construct(array $data = [])
    {
        if (isset($data['void'])) {
            $this->void = new PayuVoidData($data['void']);
        }
        if (isset($data['brazil'])) {
            $this->brazil = new PayuBrazilData($data['brazil']);
        }
        $this->auth_token = $data['auth_token'] ?? null;
    }
}

class PayuVoidData
{
    public string $last_status = '';

    public function __construct(array $data = [])
    {
        $this->last_status = $data['last_status'] ?? '';
    }
}

class PayuBrazilData
{
    public string $session_id = '';

    public function __construct(array $data = [])
    {
        $this->session_id = $data['session_id'] ?? '';
    }
}

class SibsData
{
    public string $form_context = '';
    public bool $purchase_request_sent = false;
    public string $transaction_signature = '';

    public function __construct(array $data = [])
    {
        $this->form_context = $data['form_context'] ?? '';
        $this->purchase_request_sent = $data['purchase_request_sent'] ?? false;
        $this->transaction_signature = $data['transaction_signature'] ?? '';
    }
}

class AdyenData
{
    public ?AdyenLinkData $link = null;
    public string $payment_method = '';

    public function __construct(array $data = [])
    {
        if (isset($data['link'])) {
            $this->link = new AdyenLinkData($data['link']);
        }
        $this->payment_method = $data['payment_method'] ?? '';
    }
}

class AdyenLinkData
{
    public string $id = '';

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? '';
    }
}

class UrlsData
{
    public string $fail_url = '';
    public string $success_url = '';

    public function __construct(array $data = [])
    {
        $this->fail_url = $data['fail_url'] ?? '';
        $this->success_url = $data['success_url'] ?? '';
    }
}

class AdelyaData
{
    public string $card = '';
    public bool $sent = false;

    public function __construct(array $data = [])
    {
        $this->card = $data['card'] ?? '';
        $this->sent = $data['sent'] ?? false;
    }
}

class EdenredData
{
    public string $authorization_id = '';

    public function __construct(array $data = [])
    {
        $this->authorization_id = $data['authorization_id'] ?? '';
    }
}

class MonizzeData
{
    public string $transaction_id = '';

    public function __construct(array $data = [])
    {
        $this->transaction_id = $data['transaction_id'] ?? '';
    }
}

class ParcifyData
{
    public string $order_id = '';

    public function __construct(array $data = [])
    {
        $this->order_id = $data['order_id'] ?? '';
    }
}

class PayconiqData
{
    public string $payment_id = '';

    public function __construct(array $data = [])
    {
        $this->payment_id = $data['payment_id'] ?? '';
    }
}

class JoynBadgeData
{
    public int $points = 0;
    public string $token = '';
    public string $image_url = '';

    public function __construct(array $data = [])
    {
        $this->points = $data['points'] ?? 0;
        $this->token = $data['token'] ?? '';
        $this->image_url = $data['image_url'] ?? '';
    }
}

class ExtraInfoData
{
    public mixed $table_number = null; // Can be int, array, or null
    public string $note = '';
    public array $rawData = []; // Store any extra fields

    public function __construct(array $data = [])
    {
        $this->table_number = $data['table_number'] ?? null;
        $this->note = $data['note'] ?? '';
        $this->rawData = $data; // Preserve all original data
    }
}

class StatisticsData
{
    public string $app_space = '';
    public string $user_agent = '';
    public string $device_info = '';

    public function __construct(array $data = [])
    {
        $this->app_space = $data['app_space'] ?? '';
        $this->user_agent = $data['user_agent'] ?? '';
        $this->device_info = $data['device_info'] ?? '';
    }
}

class WarrantyData
{
    public string $bank_account = '';

    public function __construct(array $data = [])
    {
        $this->bank_account = $data['bank_account'] ?? '';
    }
}

class XerxesData
{
    public string $transaction_id = '';

    public function __construct(array $data = [])
    {
        $this->transaction_id = $data['transaction_id'] ?? '';
    }
}

class WebpayData
{
    public string $token = '';

    public function __construct(array $data = [])
    {
        $this->token = $data['token'] ?? '';
    }
}
