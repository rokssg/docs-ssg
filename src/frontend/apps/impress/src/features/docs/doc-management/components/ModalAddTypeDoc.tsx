import {
  Button,
  Modal,
  ModalSize,
  VariantType,
  useToastProvider,
  Select,
} from '@openfun/cunningham-react';
import { t } from 'i18next';
import { Box, Text } from '@/components';
import React, { useState } from 'react';

interface Template {
  id: string;
  name: string;
}

interface ModalAddTypeDocProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (templateId: string) => void;
  templates: Template[]; // Pass the list of templates as a prop
}

export const ModalAddTypeDoc = ({
  isOpen,
  onClose,
  onConfirm,
  templates,
}: ModalAddTypeDocProps) => {
  const { toast } = useToastProvider();
  const [selectedTemplate, setSelectedTemplate] = useState<string>(templates[0]?.id || '');

  const handleConfirm = () => {
    onConfirm(selectedTemplate);
    toast(t('The document will be created from the selected template.'), VariantType.SUCCESS, {
      duration: 4000,
    });
  };

  return (
    <Modal
      isOpen={isOpen}
      closeOnClickOutside
      onClose={onClose}
      rightActions={
        <>
          <Button
            aria-label={t('Cancel creation')}
            color="secondary"
            fullWidth
            onClick={onClose}
          >
            {t('Cancel')}
          </Button>
          <Button
            aria-label={t('Confirm creation')}
            color="primary"
            fullWidth
            onClick={handleConfirm}
            disabled={!selectedTemplate}
          >
            {t('Create')}
          </Button>
        </>
      }
      size={ModalSize.SMALL}
      title={
        <Text $size="h6" as="h6" $margin={{ all: '0' }} $align="flex-start" $variation="1000">
          {t('Create a new doc')}
        </Text>
      }
    >
      <Box aria-label={t('Content modal to create document')}>
        <Text $size="sm" $variation="600" $margin={{ bottom: '1rem' }}>
          {t('Choose a template to create your new document:')}
        </Text>
        <Select
                  aria-label={t('Select template')}
                  options={templates.map((tpl) => ({
                      label: tpl.name,
                      value: tpl.id,
                  }))}
                  value={selectedTemplate}
                  onChange={(e) => setSelectedTemplate((e.target.value ?? '').toString())}
                  fullWidth label={''}        />
      </Box>
    </Modal>
  );
};