/**
 * DTC Blog/CMS Client-Side Scripts
 * MSSV: DTC245180035 - Ha Duc Trung
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Live Markdown Preview Handler in Editor
  const btnTogglePreview = document.getElementById('btn-toggle-preview');
  const markdownInput = document.getElementById('markdown-input');
  const previewContainer = document.getElementById('preview-container');
  const csrfField = document.getElementById('csrf-token-field');

  if (btnTogglePreview && markdownInput && previewContainer) {
    let isPreviewMode = false;

    btnTogglePreview.addEventListener('click', async () => {
      if (!isPreviewMode) {
        // Switch to preview mode
        const content = markdownInput.value;
        const csrfToken = csrfField ? csrfField.value : '';

        previewContainer.innerHTML = '<p class="text-muted">Đang tải bản xem trước...</p>';
        markdownInput.classList.add('d-none');
        previewContainer.classList.remove('d-none');
        btnTogglePreview.textContent = 'Quay lại chế độ Soạn thảo (Edit)';
        isPreviewMode = true;

        try {
          const res = await fetch('/author/posts/preview', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({ content, _csrf: csrfToken })
          });

          if (!res.ok) throw new Error('Không thể tải preview');
          const data = await res.json();
          previewContainer.innerHTML = data.html || '<p class="text-muted">Nội dung xem trước trống.</p>';
        } catch (err) {
          previewContainer.innerHTML = '<p class="text-danger">Lỗi khi tải bản xem trước Markdown.</p>';
        }
      } else {
        // Switch back to edit mode
        previewContainer.classList.add('d-none');
        markdownInput.classList.remove('d-none');
        btnTogglePreview.textContent = 'Xem trước nội dung (Live Preview)';
        markdownInput.focus();
        isPreviewMode = false;
      }
    });
  }

  // 2. Comment Reply button handler
  const replyButtons = document.querySelectorAll('.btn-reply-comment');
  const commentForm = document.getElementById('comment-form');
  const parentIdInput = document.getElementById('comment-parent-id');
  const replyNotice = document.getElementById('reply-notice');
  const replyAuthorName = document.getElementById('reply-author-name');
  const cancelReplyBtn = document.getElementById('cancel-reply-btn');

  if (replyButtons.length > 0 && commentForm && parentIdInput) {
    replyButtons.forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const commentId = btn.getAttribute('data-comment-id');
        const author = btn.getAttribute('data-author');

        parentIdInput.value = commentId;
        if (replyNotice && replyAuthorName) {
          replyAuthorName.textContent = author;
          replyNotice.classList.remove('d-none');
        }
        commentForm.scrollIntoView({ behavior: 'smooth' });
        const commentInput = commentForm.querySelector('textarea[name="content"]');
        if (commentInput) commentInput.focus();
      });
    });

    if (cancelReplyBtn) {
      cancelReplyBtn.addEventListener('click', (e) => {
        e.preventDefault();
        parentIdInput.value = '';
        if (replyNotice) replyNotice.classList.add('d-none');
      });
    }
  }

  // 3. Auto dismiss success alerts after 6 seconds
  const autoAlerts = document.querySelectorAll('.alert-success');
  if (autoAlerts.length > 0) {
    setTimeout(() => {
      autoAlerts.forEach(al => {
        al.style.transition = 'opacity 0.5s ease';
        al.style.opacity = '0';
        setTimeout(() => al.remove(), 500);
      });
    }, 6000);
  }

  // 4. Reading progress indicator on detail page
  const progressBar = document.getElementById('reading-progress');
  if (progressBar) {
    window.addEventListener('scroll', () => {
      const winScroll = document.documentElement.scrollTop || document.body.scrollTop;
      const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
      const scrolled = height > 0 ? (winScroll / height) * 100 : 0;
      progressBar.style.width = scrolled + '%';
    });
  }

  // 5. Code block copy button
  document.querySelectorAll('.markdown-body pre').forEach(pre => {
    const copyBtn = document.createElement('button');
    copyBtn.className = 'btn-copy-code';
    copyBtn.setAttribute('type', 'button');
    copyBtn.setAttribute('title', 'Sao chép đoạn mã');
    copyBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg><span>Sao chép</span>';
    
    copyBtn.addEventListener('click', async () => {
      try {
        const codeElem = pre.querySelector('code');
        const text = codeElem ? codeElem.innerText : pre.innerText;
        await navigator.clipboard.writeText(text);
        copyBtn.classList.add('copied');
        copyBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg><span>Đã chép!</span>';
        setTimeout(() => {
          copyBtn.classList.remove('copied');
          copyBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg><span>Sao chép</span>';
        }, 2000);
      } catch (e) {
        console.error('Không thể sao chép mã:', e);
      }
    });

    pre.appendChild(copyBtn);
  });
});