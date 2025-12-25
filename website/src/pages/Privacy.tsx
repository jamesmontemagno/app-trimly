const PrivacyPage = () => {
  return (
    <article className="section">
      <div className="container legal-page">
        <h1>Privacy Policy</h1>
        <p className="legal-meta">Last updated: December 18, 2025</p>

        <p>
          This Privacy Policy explains how TrimTally, a product of Refractored LLC ("we", "our", or "us"), handles
          information when you use the TrimTally mobile applications and website. TrimTally is designed to respect your
          privacy by default. We do not create user accounts, we do not profile you, and we do not sell or share your
          information with advertisers.
        </p>

        <h2>Information We Store</h2>
        <ul>
          <li>
            <strong>On-device entries.</strong> Weight logs, goals, settings, and achievements stay on the Apple device
            where you entered them. The data is stored using Apple&#39;s secure storage technologies and never transmitted to
            our servers.
          </li>
          <li>
            <strong>Optional iCloud sync.</strong> You can choose to sync TrimTally data with your personal iCloud account
            to keep entries available across your devices. When enabled, storage and transmission are managed entirely by
            Apple. Your information remains encrypted in transit and at rest according to Apple&#39;s policies, and Refractored
            LLC cannot access it.
          </li>
        </ul>

        <h2>Information We Do Not Collect</h2>
        <p>
          We do not collect personal identifiers, contact information, location, biometrics, payment details, or device
          analytics. TrimTally does not use third-party analytics SDKs, ad networks, or tracking pixels. The only network
          calls the app makes are those required by Apple services you explicitly enable (such as iCloud or HealthKit).
        </p>

        <h2>Health Data</h2>
        <p>
          If you connect to Apple Health, TrimTally writes and reads weight data through the HealthKit framework with your
          permission. Apple Health controls access, auditing, and revocation. Refractored LLC never sees your Health data
          and does not store it on external servers.
        </p>

        <h2>Your Choices and Control</h2>
        <ul>
          <li>
            <strong>Stay local.</strong> Simply avoid enabling iCloud sync to keep all TrimTally data stored only on the
            device you are using.
          </li>
          <li>
            <strong>Disable sync at any time.</strong> You can turn iCloud off in TrimTally or in iOS/macOS Settings &gt;
            Apple ID &gt; iCloud. Existing iCloud backups remain under your Apple account until you delete them.
          </li>
          <li>
            <strong>Delete your data.</strong> Remove entries individually inside TrimTally or delete the app to remove all
            locally stored information. If iCloud sync was enabled, delete TrimTally data from iCloud Drive or Health app as
            needed.
          </li>
        </ul>

        <h2>Children&apos;s Privacy</h2>
        <p>
          TrimTally is not marketed to children under 13. If you learn that a child under 13 has provided us with
          information, please contact us and we will help you delete it.
        </p>

        <h2>Security</h2>
        <p>
          TrimTally relies on Apple&#39;s platform security, including full-disk encryption and secure enclave protections,
          to safeguard on-device data. All optional sync features use Apple-managed encryption. We encourage you to protect
          your devices with a passcode and keep your Apple ID secure.
        </p>

        <h2>Changes to This Policy</h2>
        <p>
          We may update this Privacy Policy to reflect new features or regulatory requirements. When we make changes, we
          will update the "Last updated" date above and publish the new version at this URL.
        </p>

        <h2>Contact</h2>
        <p>
          If you have any questions, reach out to Refractored LLC at{' '}
          <a href="mailto:refractoredllc@gmail.com">refractoredllc@gmail.com</a>.
        </p>
      </div>
    </article>
  )
}

export default PrivacyPage
