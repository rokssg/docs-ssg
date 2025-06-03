import React, { useState } from 'react';
import { Modal, ModalSize, Button, Input } from '@openfun/cunningham-react';
import { Box, Text } from '@/components';
import { useTranslation } from 'react-i18next';
import { useResponsiveStore } from '@/stores';

interface GenerateTemplateModalProps {
  isOpen: boolean;
  initialTitle: string;
  onClose: () => void;
  onConfirm: (title: string) => void;
}

export const GenerateTemplateModal = ({
  initialTitle,
  onClose,
  onConfirm,
}: GenerateTemplateModalProps) => {
  const { t } = useTranslation();
  const [title, setTitle] = useState(initialTitle);
  const { isDesktop } = useResponsiveStore();

  return (
    <Modal
      isOpen
      closeOnClickOutside
      data-testid="doc-share-modal"
      aria-label={t('Share modal')}
      size={isDesktop ? ModalSize.LARGE : ModalSize.FULL}
      onClose={onClose}
      title={<Box $align="flex-start">{t('Generate Template')}</Box>}
    >
      <Box $direction="column" $gap="md">
        <Text>{t('Edit the template title if needed:')}</Text>
        <Input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder={t('Template title')}
          autoFocus
        />
        <Box $direction="row" $gap="sm" $justify="flex-end">
          <Button onClick={onClose} color="secondary">
            {t('Cancel')}
          </Button>
          <Button
            onClick={() => onConfirm(title)}
            color="primary"
            disabled={!title.trim()}
          >
            {t('Generate')}
          </Button>
        </Box>
      </Box>
    </Modal>
  );
};
