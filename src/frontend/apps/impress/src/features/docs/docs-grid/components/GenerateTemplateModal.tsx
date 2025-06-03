import React, { useState } from 'react';
import { Modal, Button } from '@openfun/cunningham-react';
import { Box, Text, TextInput } from '@/components'
import { useTranslation } from 'react-i18next';

interface GenerateTemplateModalProps {
  isOpen: boolean;
  initialTitle: string;
  onClose: () => void;
  onConfirm: (title: string) => void;
}

export const GenerateTemplateModal = ({
  isOpen,
  initialTitle,
  onClose,
  onConfirm,
}: GenerateTemplateModalProps) => {
  const { t } = useTranslation();
  const [title, setTitle] = useState(initialTitle);

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={t('Generate Template')}>
      <Box $direction="column" $gap="md">
        <Text>{t('Edit the template title if needed:')}</Text>
        <TextInput
          value={title}
          onChange={e => setTitle(e.target.value)}
          placeholder={t('Template title')}
          autoFocus
        />
        <Box $direction="row" $gap="sm" $justify="flex-end">
          <Button onClick={onClose} $variation="secondary">
            {t('Cancel')}
          </Button>
          <Button
            onClick={() => onConfirm(title)}
            $variation="primary"
            disabled={!title.trim()}
          >
            {t('Generate')}
          </Button>
        </Box>
      </Box>
    </Modal>
  );
};