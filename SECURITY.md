# Security Policy

## 🔒 Supported Versions

We actively support the following versions of dcon with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | ✅ Yes             |
| < 0.1   | ❌ No              |

## 🚨 Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in dcon, please report it responsibly.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing: **hey@emaaad.com**

Include the following information in your report:

- **Description** of the vulnerability
- **Steps to reproduce** the issue
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)
- **Your contact information** for follow-up

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 5 business days
- **Updates**: We will keep you informed of our progress throughout the investigation
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Security Best Practices

When using dcon:

1. **Database Credentials**: Never hardcode database passwords in scripts or configuration files
2. **Connection Security**: Use encrypted connections (SSL/TLS) when connecting to remote databases
3. **Access Control**: Follow the principle of least privilege for database user accounts
4. **Updates**: Keep dcon updated to the latest version to receive security patches
5. **Environment Variables**: Use environment variables or secure credential management for sensitive data

### Responsible Disclosure

We follow responsible disclosure practices:

- We will work with you to understand and resolve the issue
- We will credit you for the discovery (unless you prefer to remain anonymous)
- We will coordinate the disclosure timeline with you
- We will not take legal action against researchers who follow responsible disclosure

### Security Features

dcon includes several security features:

- **No credential storage**: Credentials are not stored persistently
- **Secure connections**: Support for SSL/TLS database connections
- **Input validation**: SQL injection prevention through parameterized queries
- **Audit logging**: Connection and query logging capabilities

## 🛡️ Security Considerations

### Database Security

- Always use strong, unique passwords for database accounts
- Limit database user privileges to only what's necessary
- Use network security (firewalls, VPNs) to protect database access
- Regularly audit database access logs

### CLI Security

- Be cautious when using dcon in shared environments
- Clear command history if it contains sensitive information
- Use secure methods to pass credentials (environment variables, prompts)

## 📞 Contact

For security-related questions or concerns:

- **Email**: hey@emaaad.com
- **Subject**: [SECURITY] dcon - [Brief Description]

For general questions, please use GitHub Issues or Discussions.

---

Thank you for helping keep dcon and its users safe! 🙏
